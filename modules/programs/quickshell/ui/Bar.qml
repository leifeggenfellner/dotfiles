import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "components" as Components
import "runtime" as Runtime

PanelWindow {
    id: bar

    required property var screen

    WlrLayershell.namespace: "lotm-bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Normal

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMargin
        left: Theme.barMargin
        right: Theme.barMargin
    }

    height: Theme.barHeight
    color: "transparent"

    // ── Bar background ──────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: Theme.barRadius
        color: Qt.rgba(
            Theme.base.r, Theme.base.g, Theme.base.b,
            Theme.barOpacity
        )

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.barSpacing
            anchors.rightMargin: Theme.barSpacing
            spacing: Theme.barSpacing

            // ═══════════ LEFT: Pathways ═══════════
            Components.Pathways {
                pathwayData: Runtime.ThemeLoader.pathways
                activeWorkspace: Runtime.HyprlandState.activeWorkspace
                pathwaysDir: Runtime.ThemeLoader.pathwaysDir
            }

            // ═══════════ CENTER: Clock + Context ═══════════
            Item { Layout.fillWidth: true }

            Components.RitualClock {}

            Components.WindowContext {
                windowTitle: Runtime.HyprlandState.activeWindowTitle
            }

            Item { Layout.fillWidth: true }

            // ═══════════ RIGHT: System Placeholders ═══════════
            Components.SystemPlaceholders {}
        }
    }
}
