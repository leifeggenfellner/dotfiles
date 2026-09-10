import QtQuick
import "../../components"
import "../../core"

// ── WorkspacesGlance ──────────────────────────────────────────
// Workspace indicator. Identity comes entirely from theme settings:
//   settings.items = [ { id, label, icon, color } ]
// icon follows the D-016 heuristic: a value containing "/" is an
// assetUrl spec (image file / raster output); anything else is a
// font glyph tinted with the item's color. With empty settings it
// degrades to a plain numeric readout. Services: hypr (injected).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var items: settings.items ?? []
    readonly property int active: services.hypr ? services.hypr.activeWorkspace : 1

    implicitWidth: items.length > 0 ? strip.width : fallback.width
    implicitHeight: Theme.metrics.bar.height

    WorkspaceStrip {
        id: strip

        visible: root.items.length > 0
        anchors.verticalCenter: parent.verticalCenter
        items: root.items
        activeWorkspace: root.active
        onWorkspaceActivated: workspaceId => root.services.hypr?.switchWorkspace(workspaceId)
    }

    Text {
        id: fallback
        visible: root.items.length === 0
        anchors.verticalCenter: parent.verticalCenter
        text: "ws " + root.active
        color: Theme.colors.fg.muted
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.bar
    }
}
