import QtQuick
import "../core"

// ── PlateFrame ────────────────────────────────────────────────
// A theme's frame behind a surface (D-076), from
// widgets.plates.settings[role]:
//   { src; slice; }  a nine-sliced plate
//   "window"         the window frame (D-081): the compositor's border
//                    width in the accent, and the corner pieces of
//                    widgets.ornaments placed as on windows. The border
//                    sits `reach` inside the surface, so the corners'
//                    outer part stays within it (surfaces may clip).
//   absent           nothing; the surface keeps its own look.
// Surfaces put it first in their frame and turn their own fill and
// border off while `shown`.

Item {
    id: plate

    // "panel" or "toast"
    required property string role
    // The window frame's border colour; a surface may raise an alert.
    property color rule: Theme.colors.accent.primary

    readonly property var setting: (Theme.widgetConfig("plates").settings ?? ({}))[role] ?? null
    readonly property bool framed: setting === "window"
    readonly property var piece: setting !== null && typeof setting === "object" ? setting : null
    readonly property bool shown: framed || piece !== null

    readonly property var ornaments: framed ? (Theme.widgetConfig("ornaments").settings ?? null) : null
    readonly property int size: ornaments ? (ornaments.size ?? 48) : 0
    readonly property int reach: ornaments ? (ornaments.reach ?? 6) : 0

    anchors.fill: parent
    visible: shown

    BorderImage {
        visible: plate.piece !== null
        anchors.fill: parent
        source: plate.piece ? Theme.assetUrl(plate.piece.src) : ""
        border.left: plate.piece ? plate.piece.slice[0] : 0
        border.top: plate.piece ? plate.piece.slice[1] : 0
        border.right: plate.piece ? plate.piece.slice[2] : 0
        border.bottom: plate.piece ? plate.piece.slice[3] : 0
        smooth: true
    }

    Rectangle {
        visible: plate.framed
        anchors.fill: parent
        anchors.margins: plate.reach
        color: Theme.colors.bg.mantle
        border.width: Theme.frameWidth
        border.color: plate.rule
    }

    // tl, tr, bl, br: the top-left piece, mirrored.
    Repeater {
        model: plate.ornaments ? [[1, 1], [-1, 1], [1, -1], [-1, -1]] : []

        delegate: Image {
            required property var modelData

            x: modelData[0] > 0 ? 0 : plate.width - plate.size
            y: modelData[1] > 0 ? 0 : plate.height - plate.size
            width: plate.size
            height: plate.size
            source: Theme.assetUrl(plate.ornaments.corner)
            sourceSize.width: plate.size * 2
            sourceSize.height: plate.size * 2
            smooth: true
            transform: Scale {
                origin.x: plate.size / 2
                origin.y: plate.size / 2
                xScale: modelData[0]
                yScale: modelData[1]
            }
        }
    }
}
