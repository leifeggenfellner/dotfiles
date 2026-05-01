import QtQuick
import "../.."
import "../../services" as Services

// Shared ritual tooltip — solver-positioned below the parent item.
// Place inside any component and bind `text` + `visible`.
Item {
    id: tooltipRoot

    property string text: ""

    // Keep tooltip inside the visible window bounds.
    property real edgePadding: Theme.overlayEdgePad

    // ── Overlay registration ─────────────────────────────────
    property string _overlayId: ""

    onVisibleChanged: {
        if (visible && text !== "") {
            _overlayId = Services.OverlayManager.push({
                type: Services.OverlayManager.typeTooltip,
                anchor: "floating",
                desiredX: _desiredSceneX(),
                desiredY: _desiredSceneY(),
                width: width,
                height: height
            });
        } else {
            if (_overlayId !== "")
                Services.OverlayManager.remove(_overlayId);
            _overlayId = "";
        }
    }

    function _desiredSceneX() {
        if (!parent)
            return 0;
        let pos = parent.mapToItem(null, 0, 0);
        return pos.x + (parent.width - width) / 2;
    }

    function _desiredSceneY() {
        if (!parent)
            return 0;
        let pos = parent.mapToItem(null, 0, 0);
        return pos.y + parent.height + 12;  // always below icon, no viewport clamping
    }

    // ── Solver-driven suppression ────────────────────────────
    // If a higher-priority overlay collides, hide this tooltip.
    readonly property bool _suppressed: {
        if (_overlayId === "")
            return false;
        let entry = Services.OverlayManager.find(_overlayId);
        if (!entry)
            return false;
        let occupied = [];
        let all = Services.OverlayManager.overlays;
        for (let i = 0; i < all.length; i++) {
            if (all[i].id !== _overlayId && all[i].visible)
                occupied.push(all[i]);
        }
        return Services.OverlayLayoutSolver.shouldSuppress(entry, occupied);
    }

    // Position below the parent, centered, with edge clamping

    x: {
        if (!parent)
            return 0;

        const parentScenePos = parent.mapToItem(null, 0, 0);
        const centeredLocalX = (parent.width - width) / 2;
        const centeredSceneX = parentScenePos.x + centeredLocalX;

        let viewportItem = parent;
        while (viewportItem.parent)
            viewportItem = viewportItem.parent;

        const viewportWidth = viewportItem.width;
        const minSceneX = edgePadding;
        const maxSceneX = viewportWidth - width - edgePadding;
        const clampedSceneX = Math.max(minSceneX, Math.min(centeredSceneX, maxSceneX));

        return clampedSceneX - parentScenePos.x;
    }

    y: parent ? parent.height + 12 : 0

    width: tooltipContent.width
    height: tooltipContent.height
    z: Theme.overlayZTooltip

    opacity: (visible && !_suppressed) ? 1.0 : 0.0
    scale: (visible && !_suppressed) ? 1.0 : 0.92

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animDurationOverlay
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: Theme.animDurationOverlay
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: tooltipContent
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 10
        radius: 6
        color: Qt.rgba(0.08, 0.07, 0.06, 0.92)
        border.width: 1
        border.color: Qt.rgba(0.75, 0.64, 0.43, 0.25)

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: tooltipRoot.text
            color: Theme.subtext1
            font {
                family: Theme.fontDisplay
                pixelSize: 11
                letterSpacing: 0.8
            }
        }
    }
}
