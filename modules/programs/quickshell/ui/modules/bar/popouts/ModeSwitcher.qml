import QtQuick
import "../../../" as Ui

Item {
    id: switcher

    required property color pathwayColor
    required property string currentMode
    property var modes: [
        {
            id: "wifi",
            label: "󰤨  WiFi"
        },
        {
            id: "ethernet",
            label: "󰈀  Ethernet"
        },
        {
            id: "bluetooth",
            label: "󰂯  Bluetooth"
        }
    ]

    signal modeSelected(string id)

    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(Ui.Theme.base.r, Ui.Theme.base.g, Ui.Theme.base.b, 0.55)
        border.width: 1
        border.color: Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, 0.5)

        Row {
            anchors.fill: parent
            anchors.margins: 3
            spacing: 2

            Repeater {
                model: switcher.modes

                Rectangle {
                    id: pill
                    required property var modelData
                    readonly property bool isActive: switcher.currentMode === modelData.id
                    width: (parent.width - (switcher.modes.length - 1) * 2) / switcher.modes.length
                    height: parent.height
                    radius: 6
                    color: isActive ? Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, 0.85) : "transparent"
                    border.width: isActive ? 1 : 0
                    border.color: Qt.rgba(switcher.pathwayColor.r, switcher.pathwayColor.g, switcher.pathwayColor.b, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: pill.modelData.label
                        font {
                            family: Ui.Theme.fontMono
                            pixelSize: 9
                            weight: Font.Medium
                        }
                        color: pill.isActive ? Ui.Theme.text : Ui.Theme.subtext0
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: switcher.modeSelected(pill.modelData.id)
                    }
                }
            }
        }
    }
}
