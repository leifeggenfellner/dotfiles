import QtQuick
import "../../core"

// ── RailPlaque ────────────────────────────────────────────────
// A recessed panel behind one region of the rail bar (D-063). Sits
// in the same parent as `target` and follows its geometry. The theme
// piece is nine-sliced; without one it is a token-drawn well.

Item {
    id: plaque

    required property Item target
    // { src; slice: [left top right bottom] } from
    // widgets.bar.settings.frame.plaque, or null
    property var piece: null

    readonly property int pad: Theme.metrics.space.sm
    readonly property var slice: piece ? piece.slice : [0, 0, 0, 0]

    x: target.x - pad
    width: target.width + pad * 2
    anchors.verticalCenter: parent.verticalCenter
    height: parent.height - Theme.metrics.space.xs

    BorderImage {
        visible: plaque.piece !== null
        anchors.fill: parent
        source: plaque.piece ? Theme.assetUrl(plaque.piece.src) : ""
        border.left: plaque.slice[0]
        border.top: plaque.slice[1]
        border.right: plaque.slice[2]
        border.bottom: plaque.slice[3]
    }

    Rectangle {
        visible: plaque.piece === null
        anchors.fill: parent
        radius: Theme.metrics.radius.small
        color: Theme.colors.bg.sunken
        border.width: 1
        border.color: Theme.colors.bg.surface2
    }
}
