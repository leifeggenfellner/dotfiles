import QtQuick
import "../../../" as Ui

Item {
    id: search

    required property color pathwayColor
    property alias text: input.text
    property string placeholder: ""
    property string iconGlyph: "󰍉"

    signal cleared

    implicitHeight: 30

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(Ui.Theme.base.r, Ui.Theme.base.g, Ui.Theme.base.b, 0.52)
        border.width: 1
        border.color: Qt.rgba(search.pathwayColor.r, search.pathwayColor.g, search.pathwayColor.b, 0.25)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: search.iconGlyph
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 11
                }
                color: Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.8)
            }

            TextInput {
                id: input
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 52
                clip: true
                color: Ui.Theme.text
                selectedTextColor: Ui.Theme.base
                selectionColor: Qt.rgba(search.pathwayColor.r, search.pathwayColor.g, search.pathwayColor.b, 0.45)
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 10
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length > 0
                text: "Clear"
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 9
                }
                color: Qt.rgba(search.pathwayColor.r, search.pathwayColor.g, search.pathwayColor.b, 0.85)

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        input.text = "";
                        search.cleared();
                    }
                }
            }
        }
    }
}
