import QtQuick
import "../" as Ui

Rectangle {
    id: root

    property string label: ""
    property bool active: false
    property bool chipEnabled: true
    property color accentColor: Ui.Theme.accent
    signal toggled

    implicitWidth: _label.implicitWidth + 18
    implicitHeight: 22
    radius: 11

    color: !chipEnabled ? Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, 0.22) : (active ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, _area.containsMouse ? 0.22 : 0.14) : Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, _area.containsMouse ? 0.55 : 0.35))

    border.width: 1
    border.color: active ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.40) : Qt.rgba(Ui.Theme.surface1.r, Ui.Theme.surface1.g, Ui.Theme.surface1.b, 0.40)

    Behavior on color {
        ColorAnimation {
            duration: Ui.Theme.animDurationFast
        }
    }

    Text {
        id: _label
        anchors.centerIn: parent
        text: root.label
        font {
            family: Ui.Theme.fontMono
            pixelSize: 9
        }
        color: !root.chipEnabled ? Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.45) : (root.active ? root.accentColor : Ui.Theme.subtext0)
    }

    MouseArea {
        id: _area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        cursorShape: root.chipEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.chipEnabled) {
                root.toggled();
            }
        }
    }
}
