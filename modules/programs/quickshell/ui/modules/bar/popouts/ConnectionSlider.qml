import QtQuick
import "./pages" as Pages
import "../../../services" as Services
import "../../../" as Ui

Item {
    id: slider

    required property color pathwayColor

    signal deviceFocused(string id)
    signal deviceUnfocused

    function unfocusCurrent() {
        if (Services.NetworkState.mode === "wifi")
            wifiPage.unfocus();
        else if (Services.NetworkState.mode === "bluetooth")
            btPage.unfocus();
    }

    Pages.WifiPage {
        id: wifiPage
        anchors.fill: parent
        opacity: Services.NetworkState.mode === "wifi" ? 1 : 0
        visible: opacity > 0
        enabled: visible
        devices: Services.NetworkState.filteredDevices
        focusedId: Services.NetworkState.focusedId
        activeConnectionName: Services.NetworkState.activeConnectionName
        wifiEnabled: Services.NetworkState.wifiEnabled
        status: Services.NetworkState.status
        pathwayColor: slider.pathwayColor
        onFocusRequested: function (id) {
            slider.deviceFocused(id);
        }
        onUnfocusRequested: slider.deviceUnfocused()

        Behavior on opacity {
            NumberAnimation {
                duration: Ui.Theme.animDurationOverlay
                easing.type: Easing.OutCubic
            }
        }
    }

    Pages.EthernetPage {
        id: ethPage
        anchors.fill: parent
        opacity: Services.NetworkState.mode === "ethernet" ? 1 : 0
        visible: opacity > 0
        enabled: visible
        devices: Services.NetworkState.devices
        focusedId: Services.NetworkState.focusedId
        pathwayColor: slider.pathwayColor
        onFocusRequested: function (id) {
            slider.deviceFocused(id);
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Ui.Theme.animDurationOverlay
                easing.type: Easing.OutCubic
            }
        }
    }

    Pages.BluetoothPage {
        id: btPage
        anchors.fill: parent
        opacity: Services.NetworkState.mode === "bluetooth" ? 1 : 0
        visible: opacity > 0
        enabled: visible
        devices: Services.NetworkState.devices
        focusedId: Services.NetworkState.focusedId
        activeConnectionName: Services.NetworkState.activeConnectionName
        status: Services.NetworkState.status
        pathwayColor: slider.pathwayColor
        onFocusRequested: function (id) {
            slider.deviceFocused(id);
        }
        onUnfocusRequested: slider.deviceUnfocused()

        Behavior on opacity {
            NumberAnimation {
                duration: Ui.Theme.animDurationOverlay
                easing.type: Easing.OutCubic
            }
        }
    }
}
