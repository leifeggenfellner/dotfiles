import QtQuick
import "../.."

Item {
    id: core

    property color pathwayColor: Theme.accent
    property string iconGlyph: ""
    property string labelText: ""

    implicitWidth: 92
    implicitHeight: 92

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(core.pathwayColor.r, core.pathwayColor.g, core.pathwayColor.b, 0.55)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -7
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: Qt.rgba(core.pathwayColor.r, core.pathwayColor.g, core.pathwayColor.b, 0.18)
    }

    Text {
        anchors.centerIn: parent
        text: core.iconGlyph
        font.family: Theme.fontMono
        font.pixelSize: 30
        color: core.pathwayColor
        opacity: 0.95
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6
        width: 180
        text: core.labelText
        font.family: Theme.fontMono
        font.pixelSize: 10
        color: Theme.text
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
    }
}
