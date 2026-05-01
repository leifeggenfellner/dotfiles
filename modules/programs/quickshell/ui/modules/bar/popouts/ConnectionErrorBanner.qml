import QtQuick
import "../../../components" as Components
import "../../../" as Ui

Item {
    id: banner

    property string message: ""
    property bool retryEnabled: true

    signal retryRequested

    visible: message.length > 0
    implicitHeight: 38

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(0.9, 0.2, 0.2, 0.12)
        border.width: 1
        border.color: Qt.rgba(0.9, 0.2, 0.2, 0.3)

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "󰅖"
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 12
                }
                color: Qt.rgba(0.9, 0.3, 0.3, 0.9)
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: banner.message || "Connection failed"
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 10
                }
                color: Qt.rgba(0.9, 0.3, 0.3, 0.85)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24 - retryButton.implicitWidth - 16
                elide: Text.ElideRight
            }

            Components.ActionButton {
                id: retryButton
                visible: banner.retryEnabled
                anchors.verticalCenter: parent.verticalCenter
                label: "Retry"
                accent: false
                onTriggered: banner.retryRequested()
            }
        }
    }
}
