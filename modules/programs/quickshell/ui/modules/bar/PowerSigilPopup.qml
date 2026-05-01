import QtQuick
import QtQuick.Effects
import Quickshell.Io
import "../.."
import "../../services" as Services
import "./" as Bar

Bar.SigilPopupBase {
    id: popup

    namespaceTag: "lotm-power-popup"
    openState: Services.PowerMenuState.menuOpen
    popupWidth: 128
    popupHeight: panelColumn.implicitHeight + 12
    extraTopMargin: Theme.barMargin
    hoverCloseDelayMs: 0
    enableEscape: false
    useScaleAnimation: false
    frameRadius: 10
    frameColor: Qt.rgba(0.10, 0.09, 0.08, 0.96)
    accentColor: Qt.rgba(0.75, 0.64, 0.43, 1.0)
    frameBorderOpacity: 0.30

    onCloseRequested: Services.PowerMenuState.menuOpen = false

    function catalogEntry(id) {
        for (let i = 0; i < Services.ThemeLoader.pathwayCatalog.length; i++) {
            if (Services.ThemeLoader.pathwayCatalog[i].id === id)
                return Services.ThemeLoader.pathwayCatalog[i];
        }
        return {
            mainColor: "#c0a36e",
            glowColor: "#c0a36e"
        };
    }

    function runAction(commandArgs) {
        actionRunner.command = commandArgs;
        actionRunner.startDetached();
        Services.PowerMenuState.menuOpen = false;
    }

    Process {
        id: actionRunner
    }

    Column {
        id: panelColumn
        anchors.fill: parent
        anchors.margins: 6
        spacing: 5

        Repeater {
            model: [
                {
                    label: "Lock",
                    pathwayId: "chained",
                    cmd: ["lock-screen"]
                },
                {
                    label: "Logout",
                    pathwayId: "wheel_of_fortune",
                    cmd: ["hyprctl", "dispatch", "exit"]
                },
                {
                    label: "Reboot",
                    pathwayId: "abyss",
                    cmd: ["systemctl", "reboot"]
                },
                {
                    label: "Shutdown",
                    pathwayId: "death",
                    cmd: ["systemctl", "poweroff"]
                }
            ]

            delegate: Rectangle {
                id: commandItem
                required property int index
                required property var modelData

                width: parent.width
                height: 28
                radius: 7

                readonly property var catalogRef: popup.catalogEntry(modelData.pathwayId)
                readonly property color mainCol: Qt.color(catalogRef.mainColor)

                color: itemArea.containsMouse ? Qt.rgba(mainCol.r, mainCol.g, mainCol.b, 0.30) : Qt.rgba(mainCol.r, mainCol.g, mainCol.b, 0.08)
                border.width: 1
                border.color: itemArea.containsMouse ? Qt.rgba(mainCol.r, mainCol.g, mainCol.b, 0.54) : Qt.rgba(mainCol.r, mainCol.g, mainCol.b, 0.24)

                opacity: popup.openState ? 1.0 : 0.0
                x: popup.openState ? 0 : -6

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: popup.openState ? commandItem.index * 35 : 0
                        }
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Behavior on x {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: popup.openState ? commandItem.index * 35 : 0
                        }
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutQuad
                        }
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    spacing: 8

                    Item {
                        width: 14
                        height: 14

                        Image {
                            id: pathwaySvg
                            anchors.fill: parent
                            source: Services.ThemeLoader.pathwaysDir !== "" ? "file://" + Services.ThemeLoader.pathwaysDir + "/" + commandItem.modelData.pathwayId + ".svg" : ""
                            smooth: true
                            visible: status === Image.Ready
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: commandItem.mainCol
                                brightness: itemArea.containsMouse ? 0.80 : 0.72
                                contrast: -0.05
                            }
                        }

                        Image {
                            id: pathwayPng
                            anchors.fill: parent
                            source: Services.ThemeLoader.pathwaysPngDir !== "" ? "file://" + Services.ThemeLoader.pathwaysPngDir + "/" + commandItem.modelData.pathwayId + ".png" : ""
                            smooth: true
                            visible: !pathwaySvg.visible
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: commandItem.mainCol
                                brightness: itemArea.containsMouse ? 0.80 : 0.72
                                contrast: -0.05
                            }
                        }
                    }

                    Text {
                        text: commandItem.modelData.label
                        color: Theme.text
                        font {
                            family: Theme.fontDisplay
                            pixelSize: 11
                            weight: Font.Medium
                            letterSpacing: 0.8
                        }
                    }
                }

                MouseArea {
                    id: itemArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.runAction(commandItem.modelData.cmd)
                }
            }
        }
    }
}
