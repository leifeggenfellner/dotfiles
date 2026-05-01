import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"

// ── TopBar ────────────────────────────────────────────────────
// Empty bar strip. Hidden by default while the legacy bar runs;
// widgets mount here once ported. Visibility owned by ShellState.

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    visible: ShellState.topBarVisible

    WlrLayershell.namespace: "rice-topbar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.margin
        left: Theme.metrics.bar.margin
        right: Theme.metrics.bar.margin
    }

    exclusiveZone: Theme.metrics.bar.height + Theme.metrics.bar.margin
    implicitHeight: Theme.metrics.bar.height
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.metrics.radius.large
        color: Theme.colors.bg.base
        opacity: Theme.metrics.bar.opacity
        border.width: 1
        border.color: Theme.colors.bg.surface1
    }
}
