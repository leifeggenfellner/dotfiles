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
// settings.bezel (D-065) sets each sigil in a theme plate with window,
// active and urgent states and a needle; `bezel.urgent` is a colour
// token ref for the urgent rim. Middle click moves the focused window.
// settings.carousel (D-067) turns on the workspace carousel: this glance
// reports hover and scroll on its strip, and publishes where it sits
// so the carousel opens under it.

Item {
    id: root

    property var services: ({})
    property var settings: ({})
    property string screenName: ""

    readonly property var items: settings.items ?? []
    readonly property int active: services.hypr ? services.hypr.activeWorkspaceForScreen(screenName) : 1
    readonly property var bezel: settings.bezel ?? null
    readonly property bool carousel: (settings.carousel ?? null) !== null

    function turnCarousel(steps) {
        const from = ShellState.carouselScreen === root.screenName ? ShellState.carouselWorkspace : root.active;
        const at = root.items.findIndex(i => i.id === from);
        const next = Math.max(0, Math.min(root.items.length - 1, (at < 0 ? 0 : at) + steps));
        ShellState.showCarousel(root.screenName, root.items[next].id, "scroll");
    }

    implicitWidth: items.length > 0 ? strip.width : fallback.width
    implicitHeight: Theme.metrics.bar.height

    WorkspaceStrip {
        id: strip

        visible: root.items.length > 0
        anchors.verticalCenter: parent.verticalCenter
        items: root.items
        activeWorkspace: root.active
        windows: root.services.hypr?.workspaceWindows ?? ({})
        urgent: root.services.hypr?.urgentWorkspaces ?? ({})
        bezel: root.bezel
        urgentColor: Effects.colorRef(root.bezel?.urgent ?? "state.danger")
        onWorkspaceActivated: workspaceId => root.services.hypr?.switchWorkspace(workspaceId)
        onMoveRequested: workspaceId => root.services.hypr?.moveFocusedWindow(workspaceId)
        probe: root.carousel
        onHoveredWorkspaceChanged: {
            if (hoveredWorkspace >= 0)
                ShellState.setCarouselPointer(root.screenName, hoveredWorkspace);
            else if (ShellState.carouselPointer?.screen === root.screenName)
                ShellState.setCarouselPointer("", 0);
        }
        onScrolled: steps => root.turnCarousel(steps)
    }

    Connections {
        target: root.carousel ? ShellState : null
        function onCarouselSerialChanged() {
            if (ShellState.carouselScreen === root.screenName)
                ShellState.carouselAnchor = strip.mapToItem(null, strip.width / 2, 0).x;
        }
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
