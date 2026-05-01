import QtQuick
import QtQuick.Layouts
import "../../"

// ── Chip ──────────────────────────────────────────────────────
// Pill-shaped indicator. Glyph only, or glyph + label.
// Hidden when content is empty so layout collapses naturally.

Item {
    id: chip

    property string glyph: ""
    property string label: ""
    property color chipColor: Theme.text
    property bool active: false

    visible: glyph !== "" || label !== ""

    implicitWidth: row.implicitWidth + Theme.spaceXs * 2
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: chip.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 3

        Text {
            visible: chip.glyph !== ""
            text: chip.glyph
            font.pixelSize: 11
            font.family: Theme.fontMono
            color: chip.chipColor
        }

        Text {
            visible: chip.label !== ""
            text: chip.label
            font.pixelSize: 10
            font.family: Theme.fontSans
            color: chip.chipColor
        }
    }
}
