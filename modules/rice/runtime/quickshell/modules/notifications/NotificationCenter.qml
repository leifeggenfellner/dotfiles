import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/notifications"

// ── NotificationCenter ────────────────────────────────────────
// Right-edge panel rendering mock NotificationState. Real
// notification server integration is Phase 6.

PanelWindow {
    id: center

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.notificationsOpen

    // Stay mapped through the slide-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        right: Theme.metrics.bar.margin
        bottom: Theme.metrics.bar.margin
    }

    implicitWidth: 360
    color: "transparent"

    Rectangle {
        id: panel

        width: parent.width
        height: parent.height
        radius: Theme.metrics.radius.large
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: Theme.colors.bg.surface1

        // Slide in from the right edge while fading.
        x: center.open ? 0 : Theme.metrics.space.lg * 2
        opacity: center.open ? 0.96 : 0

        Behavior on x {
            MotionAnim {
                spec: center.open ? Motion.panelOpen : Motion.panelClose
            }
        }
        Behavior on opacity {
            MotionAnim {
                spec: center.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.metrics.space.lg
            spacing: Theme.metrics.space.sm

            Text {
                text: "Notifications"
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.heading
            }

            Repeater {
                model: NotificationState.notifications

                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.metrics.radius.medium
                    color: Theme.colors.bg.elevated

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.metrics.space.md
                        spacing: 2

                        Text {
                            text: modelData.app + " · " + modelData.time
                            color: Theme.colors.fg.subtle
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                        }
                        Text {
                            text: modelData.summary
                            color: Theme.colors.fg.primary
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.body
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: NotificationState.dismiss(modelData.id)
                    }
                }
            }

            Text {
                visible: NotificationState.notifications.length === 0
                text: "All quiet."
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
        }
    }
}
