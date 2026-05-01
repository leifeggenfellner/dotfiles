import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../" as Ui
import "./"

Item {
    id: root

    required property color pathwayColor

    signal requestClose

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        Item {
            Layout.fillWidth: true
            height: 40

            Column {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                spacing: 2

                Text {
                    text: {
                        let mode = Services.NetworkState.mode;
                        let status = Services.NetworkState.status;
                        if (status === "scanning")
                            return mode.charAt(0).toUpperCase() + mode.slice(1) + " • Scanning...";
                        if (status === "connecting")
                            return "Connecting...";
                        if (status === "connected")
                            return mode.charAt(0).toUpperCase() + mode.slice(1) + " • Connected";
                        if (status === "error")
                            return "Connection Failed";
                        return mode.charAt(0).toUpperCase() + mode.slice(1) + " • Idle";
                    }
                    font {
                        family: Ui.Theme.fontDisplay
                        pixelSize: 13
                        weight: Font.Medium
                    }
                    color: {
                        if (Services.NetworkState.status === "connected")
                            return root.pathwayColor;
                        if (Services.NetworkState.status === "error")
                            return Qt.rgba(0.9, 0.3, 0.3, 1);
                        return Ui.Theme.text;
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Ui.Theme.animDurationFast
                        }
                    }
                }

                Text {
                    visible: Services.NetworkState.activeConnectionName.length > 0
                    text: Services.NetworkState.activeConnectionName
                    font {
                        family: Ui.Theme.fontMono
                        pixelSize: 10
                    }
                    color: Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.75)
                }
            }

            Rectangle {
                width: 22
                height: 22
                radius: 11
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                color: _close.containsMouse ? Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, 0.7) : "transparent"
                border.width: 1
                border.color: Qt.rgba(Ui.Theme.surface1.r, Ui.Theme.surface1.g, Ui.Theme.surface1.b, _close.containsMouse ? 0.5 : 0.25)

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font {
                        family: Ui.Theme.fontMono
                        pixelSize: 10
                    }
                    color: Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.8)
                }

                MouseArea {
                    id: _close
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.requestClose()
                }
            }
        }

        ModeSwitcher {
            Layout.fillWidth: true
            pathwayColor: root.pathwayColor
            currentMode: Services.NetworkState.mode
            onModeSelected: id => Services.NetworkState.mode = id
        }

        RitualSearchField {
            Layout.fillWidth: true
            visible: Services.NetworkState.mode === "wifi"
            Layout.preferredHeight: visible ? implicitHeight : 0
            pathwayColor: root.pathwayColor
            text: Services.NetworkState.wifiSearchQuery
            onTextChanged: {
                if (Services.NetworkState.wifiSearchQuery !== text)
                    Services.NetworkState.wifiSearchQuery = text;
            }
            onCleared: Services.NetworkState.wifiSearchQuery = ""
        }

        ConnectionSlider {
            id: slider
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            pathwayColor: root.pathwayColor
            onDeviceFocused: function (id) {
                Services.NetworkState.focusedId = id;
                Services.NetworkState.closePasswordPrompt();
            }
            onDeviceUnfocused: {
                Services.NetworkState.focusedId = "";
                Services.NetworkState.closePasswordPrompt();
            }
        }

        Loader {
            Layout.fillWidth: true
            active: Services.NetworkState.focusedId !== ""
            visible: active
            Layout.preferredHeight: active ? (item ? item.implicitHeight : 0) : 0

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Ui.Theme.animDuration
                    easing.type: Easing.OutCubic
                }
            }

            sourceComponent: ConnectionActionPanel {
                pathwayColor: root.pathwayColor
                sliderRef: slider
            }
        }

        ConnectionErrorBanner {
            Layout.fillWidth: true
            message: Services.NetworkState.status === "error" ? (Services.NetworkState.errorMessage || "Connection failed") : ""
            onRetryRequested: Services.NetworkState.retry()
        }

        Item {
            Layout.fillWidth: true
            height: 30

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Components.ToggleChip {
                    visible: Services.NetworkState.mode === "wifi"
                    label: Services.NetworkState.wifiEnabled ? "WiFi On" : "WiFi Off"
                    active: Services.NetworkState.wifiEnabled
                    chipEnabled: Services.NetworkState.status !== "connecting"
                    accentColor: root.pathwayColor
                    onToggled: Services.NetworkState.toggleWifi()
                }

                Components.ToggleChip {
                    visible: Services.NetworkState.mode === "bluetooth"
                    label: Services.NetworkState.bluetoothEnabled ? "BT On" : "BT Off"
                    active: Services.NetworkState.bluetoothEnabled
                    chipEnabled: Services.NetworkState.status !== "connecting"
                    accentColor: root.pathwayColor
                    onToggled: Services.NetworkState.toggleBluetooth()
                }
            }
        }
    }
}
