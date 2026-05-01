import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/audio"

// ── Osd ───────────────────────────────────────────────────────
// Placeholder OSD pill. Reads mock AudioState so the service→UI
// data flow is exercised from day one. Real trigger logic (volume
// change events) arrives with the OSD phase.

PanelWindow {
    id: osd

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.osdVisible

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
                name: AudioState.muted ? "volume-muted" : "volume"
                color: AudioState.muted ? Theme.colors.fg.subtle : Theme.colors.accent.primary
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 160
                height: 6
                radius: 3
                color: Theme.colors.bg.surface1

                Rectangle {
                    width: parent.width * AudioState.volume
                    height: parent.height
                    radius: parent.radius
                    color: Theme.colors.accent.primary

                    Behavior on width {
                        MotionAnim {}
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(AudioState.volume * 100) + "%"
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
