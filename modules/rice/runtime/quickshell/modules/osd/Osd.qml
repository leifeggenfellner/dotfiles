import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/audio"
import "../../services/brightness"

// ── Osd ───────────────────────────────────────────────────────
// Input-transparent feedback for user-initiated volume and brightness changes.

PanelWindow {
    id: osd

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.osdVisible
    readonly property bool brightness: ShellState.osdKind === "brightness"
    readonly property bool available: brightness ? BrightnessState.available : AudioState.available
    readonly property real value: brightness ? BrightnessState.value : AudioState.volume
    readonly property string iconName: brightness ? "brightness" : (AudioState.muted ? "volume-muted" : "volume")
    readonly property string label: available ? Math.round(value * 100) + "%" : "n/a"

    // Stay mapped through the fade-out so hiding is smooth.
    visible: open || pill.opacity > 0.01

    WlrLayershell.namespace: "rice-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    margins.bottom: 64

    implicitWidth: 280
    implicitHeight: 48
    color: "transparent"

    Connections {
        target: ShellState
        function onOsdSerialChanged() {
            if (osd.brightness)
                BrightnessState.refresh();
            hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: ShellState.hideOsd()
    }

    Rectangle {
        id: pill

        anchors.fill: parent
        radius: height / 2
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: Theme.colors.bg.surface1

        opacity: osd.open ? 0.96 : 0

        Behavior on opacity {
            MotionAnim {
                spec: osd.open ? Motion.stateChange : Motion.panelClose
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: Theme.metrics.space.md

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: osd.iconName
                color: (!osd.brightness && AudioState.muted) || !osd.available ? Theme.colors.fg.subtle : Theme.colors.accent.primary
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 160
                height: 6
                radius: 3
                color: Theme.colors.bg.surface1

                Rectangle {
                    width: parent.width * osd.value
                    height: parent.height
                    radius: parent.radius
                    color: osd.available ? Theme.colors.accent.primary : Theme.colors.fg.subtle

                    Behavior on width {
                        MotionAnim {}
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: osd.label
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
