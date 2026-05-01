import QtQuick
import "../../"

// ── Plate ─────────────────────────────────────────────────────
// Layered background surface with tinted base + hairline border.
// Use as the root of any popout, card, or bar section.

Rectangle {
    id: plate

    property real bgOpacity: 0.92
    property color bgColor: Theme.base
    property color borderColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
    property real borderWidth: 1.0

    radius: Theme.popoutRadius
    color: Qt.rgba(bgColor.r, bgColor.g, bgColor.b, bgOpacity)

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: plate.borderColor
        border.width: plate.borderWidth
    }
}
