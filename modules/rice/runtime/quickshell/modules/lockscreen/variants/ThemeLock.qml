// Theme lockscreen wrapper. Embeds the selected theme UI as an Item under rice's
// ShellRoot and supplies the SDDM-shaped authentication surface it expects.
// The Loader instantiates the theme's Main.qml verbatim; ancestor-scope
// resolution supplies sddm/userModel/sessionModel/keyboard to it.

import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    // Absolute path to the selected lockscreen asset dir. Injected by rice-lock-screen.
    property string themePath: Quickshell.env("RICE_LOCK_THEME_PATH")

    readonly property var sddm: shim.sddm
    readonly property var userModel: shim.userModel
    readonly property var sessionModel: shim.sessionModel
    readonly property var config: shim.config
    readonly property var lockState: sharedLockState

    // SDDM provides `keyboard`; Quickshell does not. This stub keeps the
    // lockscreen UI quiet without adding an SDDM runtime dependency.
    readonly property QtObject keyboard: QtObject {
        property bool numLock: false
        property bool capsLock: false
    }

    property bool authenticated: false
    property bool sessionLocked: true
    property bool themeReady: false
    // Set when the theme fails to reload after it has already loaded once
    // (e.g. re-instantiated on another output after a dock unplug). From
    // then on every output uses the black password surface instead.
    property bool themeBroken: false

    // The theme (video background and all) renders on one screen only;
    // every other output gets a plain black lock surface. RICE_LOCK_OUTPUT
    // names it explicitly; otherwise pick the screen nearest the
    // horizontal middle of the layout (the centre monitor when docked,
    // the laptop panel when not).
    readonly property string primaryScreenName: {
        const screens = Quickshell.screens;
        if (screens.length === 0)
            return "";
        const wanted = Quickshell.env("RICE_LOCK_OUTPUT") || "";
        for (let i = 0; i < screens.length; i++) {
            if (screens[i].name === wanted)
                return wanted;
        }
        let left = Infinity;
        let right = -Infinity;
        for (let i = 0; i < screens.length; i++) {
            left = Math.min(left, screens[i].x);
            right = Math.max(right, screens[i].x + screens[i].width);
        }
        const mid = (left + right) / 2;
        let best = screens[0];
        for (let i = 1; i < screens.length; i++) {
            const s = screens[i];
            if (Math.abs(s.x + s.width / 2 - mid) < Math.abs(best.x + best.width / 2 - mid))
                best = s;
        }
        return best.name;
    }

    // Password entry for the black fallback surfaces, which get
    // keyboard focus whenever the cursor sits on their output. Mirrors
    // the theme's doLogin through the same shared state and shim.
    function secondaryKey(event) {
        event.accepted = true;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (sharedLockState.authPending || sharedLockState.password.length === 0)
                return;
            const password = sharedLockState.password;
            sharedLockState.authPending = true;
            sharedLockState.password = "";
            shim.sddm.login(shim.userModel.lastUser, password, Math.max(0, shim.sessionModel.lastIndex));
        } else if (event.key === Qt.Key_Escape) {
            sharedLockState.password = "";
        } else if (event.key === Qt.Key_Backspace) {
            sharedLockState.password = sharedLockState.password.slice(0, -1);
        } else if (event.text.length > 0 && event.text.charCodeAt(0) >= 0x20 && !sharedLockState.authPending) {
            if (sharedLockState.authFailed) {
                sharedLockState.authFailed = false;
                sharedLockState.errorMessage = "";
            }
            sharedLockState.password += event.text;
        }
    }

    QtObject {
        id: sharedLockState

        property string password: ""
        property bool authPending: false
        property bool authFailed: false
        property string errorMessage: ""
    }

    function failOpen(reason) {
        console.error("Theme lockscreen: failing open:", reason);
        Quickshell.execDetached(["quickshell", "-c", "rice", "ipc", "call", "ambient", "setIdleHint", "off"]);
        Quickshell.execDetached(["loginctl", "unlock-session"]);
        root.sessionLocked = false;
        Qt.quit();
    }

    SddmShim {
        id: shim
        themePath: root.themePath
    }

    Connections {
        target: shim.sddm
        function onLoginSucceeded() {
            root.authenticated = true;

            // Phase 6: clear the rice IdleVeil that was faded in by
            // ambient.lockWithVeil. Fired first so the veil starts
            // fading out while unlock-session/quit are in flight.
            // Safe when the rice shell isn't running (IPC just fails).
            Quickshell.execDetached(["quickshell", "-c", "rice", "ipc", "call", "ambient", "setIdleHint", "off"]);

            // Hyprland re-lock workaround.
            if (Quickshell.env("XDG_CURRENT_DESKTOP") === "Hyprland" || Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== "") {
                Quickshell.execDetached(["hyprctl", "keyword", "misc:allow_session_lock_restore", "1"]);
            }
            Quickshell.execDetached(["loginctl", "unlock-session"]);

            // Optional unlock chime. Off unless RICE_LOCK_CHIME
            // opts in and rice-lock-screen has exported an audio path.
            const chime = Quickshell.env("RICE_LOCK_CHIME") || "";
            const sound = Quickshell.env("RICE_LOCK_UNLOCK_SOUND") || "";
            const on = ["on", "1", "true", "yes"].indexOf(chime.toLowerCase()) >= 0;
            if (on && sound.length > 0) {
                Quickshell.execDetached(["rice-sound-play", sound]);
            }

            quitTimer.start();
        }

        // Mirrors the theme's own handler so the fallback surfaces can
        // retry when no theme instance is loaded; idempotent otherwise.
        function onLoginFailed() {
            sharedLockState.authPending = false;
            sharedLockState.authFailed = true;
            sharedLockState.errorMessage = "ACCESS DENIED";
            sharedLockState.password = "";
        }
    }

    Timer {
        id: quitTimer
        interval: 60
        onTriggered: {
            root.sessionLocked = false;
            Qt.quit();
        }
    }

    Timer {
        id: themeLoadWatchdog
        interval: 2500
        running: root.sessionLocked && !root.themeReady
        repeat: false
        onTriggered: root.failOpen("theme did not load before watchdog")
    }

    Component {
        id: themeComponent
        Loader {
            anchors.fill: parent
            source: root.themePath.length > 0 ? "file://" + root.themePath + "/Main.qml" : ""
            onLoaded: {
                root.themeReady = true;
                item.forceActiveFocus();
            }
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.error("Theme lockscreen: failed to load", source);
                    // Fail open only on the initial load; once the lock has
                    // been up with a working theme, fail closed instead.
                    if (root.themeReady)
                        root.themeBroken = true;
                    else
                        root.failOpen("theme loader error");
                }
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: root.sessionLocked

        surface: Component {
            WlSessionLockSurface {
                id: lockSurface

                readonly property bool primary: lockSurface.screen !== null && lockSurface.screen.name === root.primaryScreenName
                readonly property bool showTheme: lockSurface.primary && !root.themeBroken

                color: "black"

                // Absorb stray gestures.
                PinchHandler {
                    target: null
                }
                WheelHandler {
                    target: null
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    hoverEnabled: true
                    onWheel: wheel => wheel.accepted = true
                }

                Loader {
                    anchors.fill: parent
                    active: lockSurface.showTheme
                    sourceComponent: themeComponent
                }

                Item {
                    anchors.fill: parent
                    visible: !lockSurface.showTheme
                    focus: !lockSurface.showTheme
                    Keys.onPressed: event => root.secondaryKey(event)

                    // Minimal feedback, only when no output shows the theme
                    // (which already mirrors input typed here); otherwise
                    // stays fully black.
                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: (!root.themeReady || root.themeBroken) && (sharedLockState.password.length > 0 || sharedLockState.authPending || sharedLockState.authFailed)

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "\u2022".repeat(Math.min(sharedLockState.password.length, 32))
                            color: "white"
                            opacity: sharedLockState.authPending ? 0.4 : 0.85
                            font.pixelSize: 28
                            font.letterSpacing: 6
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: sharedLockState.authPending ? "\u2026" : sharedLockState.errorMessage
                            visible: text.length > 0
                            color: sharedLockState.authPending ? "#999999" : "#e06c6c"
                            font.pixelSize: 14
                            font.letterSpacing: 2
                        }
                    }
                }
            }
        }
    }
}
