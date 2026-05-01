import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"

// ── Dashboard ─────────────────────────────────────────────────
// Empty centered surface. Structure + visibility toggle only;
// widgets arrive in a later phase.

PanelWindow {
    id: dashboard

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.dashboardOpen

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-dashboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    implicitWidth: 720
    implicitHeight: 440
    color: "transparent"

    Rectangle {
        id: panel

        anchors.fill: parent
        radius: Theme.metrics.radius.large
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: Theme.colors.bg.surface1

        opacity: dashboard.open ? 0.96 : 0
        scale: dashboard.open ? 1 : 0.96

        Behavior on opacity {
            MotionAnim {
                spec: dashboard.open ? Motion.panelOpen : Motion.panelClose
            }
        }
        Behavior on scale {
            MotionAnim {
                spec: dashboard.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        Text {
            anchors.centerIn: parent
            text: "Dashboard"
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.heading
        }
    }
}
