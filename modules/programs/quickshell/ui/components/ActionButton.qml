import QtQuick
import ".." as Ui

Rectangle {
    id: root

    property string label: ""
    property bool accent: false
    property color accentColor: Ui.Theme.accent
    signal triggered

    implicitWidth: _btnLabel.implicitWidth + 20
    implicitHeight: 26
    radius: 6

    color: accent ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, _area.containsMouse ? 0.22 : 0.14) : Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, _area.containsMouse ? 0.55 : 0.35)
    border.width: 1
    border.color: accent ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, _area.containsMouse ? 0.55 : 0.35) : Qt.rgba(Ui.Theme.surface1.r, Ui.Theme.surface1.g, Ui.Theme.surface1.b, 0.40)

    Behavior on color {
        ColorAnimation {
            duration: Ui.Theme.animDurationFast
        }
    }

    Text {
        id: _btnLabel
        anchors.centerIn: parent
        text: root.label
        font {
            family: Ui.Theme.fontMono
            pixelSize: 10
        }
        color: root.accent ? root.accentColor : Ui.Theme.subtext1
    }

    MouseArea {
        id: _area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}
