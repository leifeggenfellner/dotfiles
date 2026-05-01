import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "../.."
import "../"

Item {
    id: tray

    property var pathwayData: []
    property int activeWorkspace: 1

    Layout.preferredHeight: parent.height
    implicitWidth: row.implicitWidth

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: SystemTray.items

            TrayItem {
                required property var modelData
                item: modelData
                pathwayData: tray.pathwayData
                activeWorkspace: tray.activeWorkspace
            }
        }
    }
}
