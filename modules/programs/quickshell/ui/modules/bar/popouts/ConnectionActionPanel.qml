import QtQuick
import "../../../components" as Components
import "../../../services" as Services
import "../../../" as Ui

Item {
    id: root

    required property color pathwayColor
    property var sliderRef: null

    implicitHeight: panelColumn.implicitHeight

    readonly property var device: {
        let id = Services.NetworkState.focusedId;
        let devs = Services.NetworkState.devices;
        for (let i = 0; i < devs.length; i++) {
            if (devs[i].id === id)
                return devs[i];
        }
        return null;
    }

    readonly property bool isConnected: device ? device.state === "connected" : false
    readonly property bool isConnecting: device ? device.state === "connecting" : false
    readonly property bool needsPassword: device ? (device.type === "wifi" && device.secured && !isConnected) : false

    function doConnect() {
        if (!device)
            return;
        if (needsPassword) {
            Services.NetworkState.openPasswordPrompt();
            return;
        }
        Services.NetworkState.connect(device.id);
    }

    function doConnectWithPassword() {
        if (!device || !needsPassword)
            return;
        Services.NetworkState.submitPassword();
    }

    function doBack() {
        Services.NetworkState.closePasswordPrompt();
        if (sliderRef && sliderRef.unfocusCurrent)
            sliderRef.unfocusCurrent();
        Services.NetworkState.focusedId = "";
    }

    Column {
        id: panelColumn
        width: parent.width
        spacing: 6

        PasswordInputPanel {
            id: passwordPanel
            width: parent.width
            visible: Services.NetworkState.passwordPanelOpen && root.needsPassword
            pathwayColor: root.pathwayColor
            deviceName: root.device ? root.device.name : ""
            password: Services.NetworkState.passwordDraft
            onPasswordChanged: {
                if (Services.NetworkState.passwordDraft !== password)
                    Services.NetworkState.passwordDraft = password;
            }
            onSubmitted: function (pw) {
                if (Services.NetworkState.passwordDraft !== pw)
                    Services.NetworkState.passwordDraft = pw;
                root.doConnectWithPassword();
            }
        }

        Row {
            width: parent.width
            spacing: 6

            Components.ActionButton {
                visible: !root.isConnected && !root.isConnecting && !Services.NetworkState.passwordPanelOpen
                label: root.needsPassword ? "Enter Password" : "Connect"
                accent: true
                accentColor: root.pathwayColor
                onTriggered: root.doConnect()
            }

            Components.ActionButton {
                visible: Services.NetworkState.passwordPanelOpen && root.needsPassword
                label: "Connect"
                accent: true
                accentColor: root.pathwayColor
                onTriggered: root.doConnectWithPassword()
            }

            Text {
                visible: root.isConnecting
                text: "Connecting..."
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 10
                }
                color: Qt.rgba(root.pathwayColor.r, root.pathwayColor.g, root.pathwayColor.b, 0.8)
                anchors.verticalCenter: parent.verticalCenter
            }

            Components.ActionButton {
                visible: root.isConnected
                label: "Disconnect"
                onTriggered: {
                    if (root.device)
                        Services.NetworkState.disconnect(root.device.id);
                }
            }

            Components.ActionButton {
                label: Services.NetworkState.passwordPanelOpen ? "Cancel" : "Back"
                onTriggered: root.doBack()
            }
        }
    }
}
