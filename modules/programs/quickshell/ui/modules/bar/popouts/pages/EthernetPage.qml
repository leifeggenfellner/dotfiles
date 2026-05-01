import QtQuick
import "../../../../components" as Components

Item {
    id: page

    required property color pathwayColor
    required property var devices
    required property string focusedId

    signal focusRequested(string id)

    Components.RitualDeviceList {
        anchors.fill: parent
        devices: page.devices
        pathwayColor: page.pathwayColor
        focusedId: page.focusedId
        emptyText: "No ethernet devices found"
        onDeviceClicked: function (id) {
            page.focusRequested(id);
        }
    }
}
