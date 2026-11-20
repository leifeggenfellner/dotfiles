import QtQuick
import "../../core"
import "../../components"

// ── RailCap ───────────────────────────────────────────────────
// One end cap of the rail bar (D-063): a theme plate with an emblem
// in its hub, bound to one shell action. The plate turns one notch
// while its action's surface is open and back when it closes; it
// never spins. Without a plate the cap is a token-drawn ring.

Item {
    id: cap

    // { action; plate?; emblem?; turn? } from widgets.bar.settings.caps
    required property var spec
    // { rest?; hover? } hub glow colour token refs
    property var glow: ({})

    readonly property string action: spec.action ?? ""
    readonly property string plate: spec.plate ?? ""
    readonly property string emblem: spec.emblem ?? ""
    readonly property bool engaged: {
        if (action === "launcher")
            return ShellState.launcherOpen;
        if (action === "dashboard")
            return ShellState.dashboardOpen;
        if (action === "power")
            return ShellState.activePopout === "power";
        return false;
    }
    // Set by the bar to fit its inset; the default fills the rail.
    property int plateSize: Theme.metrics.bar.height - Theme.metrics.space.xs

    implicitWidth: Theme.metrics.bar.height + Theme.metrics.space.sm
    implicitHeight: Theme.metrics.bar.height

    function trigger() {
        if (action === "launcher")
            ShellState.toggleLauncher();
        else if (action === "dashboard")
            ShellState.toggleDashboard();
        else if (action === "power")
            ShellState.togglePopout("power");
    }

    Item {
        id: face

        anchors.centerIn: parent
        width: cap.plateSize
        height: cap.plateSize
        rotation: cap.engaged ? (cap.spec.turn ?? 30) : 0

        Behavior on rotation {
            MotionAnim {
                spec: Motion.instrumentSettle
            }
        }

        // Under reduce-motion the notch fades in instead of turning.
        FadeIn {
            id: notchFade
            target: face
        }
        Connections {
            target: cap
            function onEngagedChanged() {
                notchFade.play();
            }
        }

        Image {
            visible: cap.plate.length > 0
            anchors.fill: parent
            source: cap.plate.length > 0 ? Theme.assetUrl(cap.plate) : ""
            sourceSize.width: cap.plateSize * 2
            sourceSize.height: cap.plateSize * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Rectangle {
            visible: cap.plate.length === 0
            anchors.fill: parent
            anchors.margins: Theme.metrics.space.xs
            radius: width / 2
            color: Theme.colors.bg.sunken
            border.width: 2
            border.color: Theme.colors.accent.frame
        }
    }

    // Candle light in the hub; hover warms it.
    Rectangle {
        anchors.centerIn: parent
        width: cap.plateSize * 0.46
        height: width
        radius: width / 2
        // Chrome: the theme's own colours, not the day's (D-078).
        color: Theme.tokenColor(mouse.containsMouse ? (cap.glow.hover ?? "state.warn") : (cap.glow.rest ?? "accent.primary"))
        opacity: mouse.containsMouse ? 0.42 : 0.16

        Behavior on opacity {
            MotionAnim {
                spec: Motion.stateChange
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
            }
        }
    }

    Image {
        readonly property int size: Math.round(cap.plateSize * 0.42)
        visible: Theme.iconIsFile(cap.emblem)
        anchors.centerIn: parent
        width: size
        height: size
        source: visible ? Theme.assetUrl(cap.emblem) : ""
        sourceSize.width: size * 2
        sourceSize.height: size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Icon {
        visible: cap.emblem.length > 0 && !Theme.iconIsFile(cap.emblem)
        anchors.centerIn: parent
        name: visible ? cap.emblem : "unknown"
        color: mouse.containsMouse ? Theme.colors.accent.frame : Theme.colors.fg.muted
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cap.trigger()
    }
}
