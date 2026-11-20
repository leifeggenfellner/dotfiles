import QtQuick
import "../core"

// ── PlateFrame ────────────────────────────────────────────────
// A theme's nine-sliced plate behind a surface (D-076): one of
// widgets.plates.settings ({ src; slice; }), or nothing. Surfaces put
// it first in their frame and turn their own fill and border off while
// `shown`, so without theme data they keep their plain look.

BorderImage {
    id: plate

    // "panel" or "toast"
    required property string role
    readonly property var piece: (Theme.widgetConfig("plates").settings ?? ({}))[role] ?? null
    readonly property bool shown: piece !== null

    visible: shown
    anchors.fill: parent
    source: shown ? Theme.assetUrl(piece.src) : ""
    border.left: shown ? piece.slice[0] : 0
    border.top: shown ? piece.slice[1] : 0
    border.right: shown ? piece.slice[2] : 0
    border.bottom: shown ? piece.slice[3] : 0
    smooth: true
}
