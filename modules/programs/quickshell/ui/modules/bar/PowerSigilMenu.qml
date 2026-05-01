import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import "../.."
import "../../services" as Services

Item {
    id: powerMenu

    Layout.preferredHeight: Theme.barHeight
    Layout.preferredWidth: 30

    property bool open: Services.PowerMenuState.menuOpen
    property string pathwaysDir: ""
    property string pathwaysPngDir: ""
    property var pathwayCatalog: []
    property var pathwayData: []
    property int activeWorkspace: 1
    property color pathwayColor: {
        const activeWs = String(activeWorkspace);
        for (let i = 0; i < pathwayData.length; i++) {
            if (String(pathwayData[i].workspace) === activeWs) {
                return Qt.color(pathwayData[i].color);
            }
        }
        return Theme.accent;
    }

    Rectangle {
        id: sigil
        width: 32
        height: 32
        radius: 16
        anchors.centerIn: parent
        color: Qt.rgba(powerMenu.pathwayColor.r, powerMenu.pathwayColor.g, powerMenu.pathwayColor.b, powerArea.containsMouse ? 0.16 : 0.09)
        border.width: 1
        border.color: Qt.rgba(powerMenu.pathwayColor.r, powerMenu.pathwayColor.g, powerMenu.pathwayColor.b, powerArea.containsMouse ? 0.48 : 0.28)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }

        Text {
            anchors.centerIn: parent
            text: ""
            color: powerMenu.pathwayColor
            opacity: powerArea.containsMouse ? 1.0 : 0.85
            font {
                family: Theme.fontMono
                pixelSize: 13
                weight: Font.Medium
            }
        }

        MouseArea {
            id: powerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.PowerMenuState.menuOpen = !Services.PowerMenuState.menuOpen
        }
    }
}
