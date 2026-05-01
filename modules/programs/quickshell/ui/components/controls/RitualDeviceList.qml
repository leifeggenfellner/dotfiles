import QtQuick
import "../.."

Item {
    id: root

    required property var devices
    required property color pathwayColor
    property string focusedId: ""
    property string emptyText: ""

    signal deviceClicked(string id)

    ListView {
        id: list
        anchors.fill: parent
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        model: root.devices

        delegate: RitualDeviceCard {
            required property var modelData
            width: list.width
            device: modelData
            pathwayColor: root.pathwayColor
            isFocused: root.focusedId === (modelData ? modelData.id : "")
            variant: "row"
            onClicked: root.deviceClicked(modelData.id)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: list.count === 0 && root.emptyText.length > 0
        text: root.emptyText
        font {
            family: Theme.fontMono
            pixelSize: 11
        }
        color: Qt.rgba(Theme.subtext0.r, Theme.subtext0.g, Theme.subtext0.b, 0.60)
        horizontalAlignment: Text.AlignHCenter
    }
}
