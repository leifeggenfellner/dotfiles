import QtQuick
import "../../../../components" as Components
import "../../../../" as Ui

Item {
    id: page

    required property color pathwayColor
    required property var devices
    required property string focusedId
    required property string activeConnectionName
    required property string status

    signal focusRequested(string id)
    signal unfocusRequested

    function unfocus() {
        orbit.unfocus();
    }

    Components.RitualOrbitField {
        id: orbit
        anchors.fill: parent
        mode: "bluetooth"
        devices: page.devices
        focusedId: page.focusedId
        pathwayColor: page.pathwayColor
        activeConnectionName: page.activeConnectionName
        wifiEnabled: true
        fieldMode: page.focusedId !== "" ? "focus" : "field"
        onDeviceFocused: function (id) {
            page.focusRequested(id);
        }
        onDeviceUnfocused: page.unfocusRequested()
    }

    Text {
        anchors.centerIn: parent
        visible: page.status === "scanning" && page.devices.length === 0
        text: "Scanning..."
        font {
            family: Ui.Theme.fontMono
            pixelSize: 11
        }
        color: Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.55)
    }
}
