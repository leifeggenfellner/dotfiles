import QtQuick
import "../.."

Item {
    id: rings

    property color pathwayColor: Theme.accent
    property int ringCount: 3
    property real orbitRadius: Math.min(width, height) * 0.34
    property real yScale: 1.0

    Repeater {
        model: rings.ringCount
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: rings.orbitRadius * 2 - (index * 34)
            height: width * rings.yScale
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(rings.pathwayColor.r, rings.pathwayColor.g, rings.pathwayColor.b, 0.11 - index * 0.025)
        }
    }
}
