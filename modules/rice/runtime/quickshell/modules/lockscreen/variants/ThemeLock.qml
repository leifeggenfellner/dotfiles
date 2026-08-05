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

    QtObject {
        id: sharedLockState

        property string password: ""
        property bool authPending: false
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
                    sourceComponent: themeComponent
                }
            }
        }
    }
}
