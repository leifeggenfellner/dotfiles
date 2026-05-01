import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: pathways

    property var pathwayData: []
    property int activeWorkspace: 1
    property string pathwaysDir: ""

    Layout.preferredHeight: parent.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.pathwaySpacing

        Repeater {
            model: pathways.pathwayData

            Item {
                id: pathwayItem
                required property var modelData
                property int wsId: modelData.workspace
                property bool active: pathways.activeWorkspace === wsId
                property string iconPath: pathways.pathwaysDir + "/" + modelData.icon

                width: Theme.pathwayIconSize + 8
                height: Theme.pathwayIconSize + 8

                Image {
                    id: icon
                    anchors.centerIn: parent
                    width: Theme.pathwayIconSize
                    height: Theme.pathwayIconSize
                    source: "file://" + pathwayItem.iconPath
                    sourceSize: Qt.size(Theme.pathwayIconSize, Theme.pathwayIconSize)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: pathwayItem.active ? 1.0 : 0.35
                    scale: pathwayItem.active ? 1.15 : 0.85

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutBack
                            overshoot: 1.5
                        }
                    }
                }

                // Active indicator underline
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: pathwayItem.active ? parent.width * 0.6 : 0
                    height: 2
                    radius: 1
                    color: Theme.accent
                    opacity: pathwayItem.active ? 1.0 : 0.0

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animDurationFast }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + pathwayItem.wsId)
                }
            }
        }
    }
}
