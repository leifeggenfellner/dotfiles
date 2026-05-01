import QtQuick
import QtQuick.Layouts
import "../.."
import "../../services" as Services

// ── Connection Sigil ─────────────────────────────────────────
// Bar trigger button for the Connection Ritual Panel.
// Shows current network status at a glance.

Item {
    id: sigil

    Layout.preferredHeight: Theme.barHeight
    Layout.preferredWidth: 30

    property var pathwayData: Services.ThemeLoader.pathways
    property int activeWorkspace: Services.HyprState.activeWorkspace
    property color pathwayColor: {
        const activeWs = String(activeWorkspace);
        for (let i = 0; i < pathwayData.length; i++) {
            if (String(pathwayData[i].workspace) === activeWs)
                return Qt.color(pathwayData[i].color);
        }
        return Theme.accent;
    }

    // Current status color derived from active connection
    property color _statusColor: {
        let devices = Services.NetworkState.devices;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].state === "connected")
                return sigil.pathwayColor;
        }
        return Theme.subtext0;
    }

    // Icon based on mode + connected state
    property string _icon: {
        let mode = Services.NetworkState.mode;
        let connected = false;
        let devices = Services.NetworkState.devices;
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].state === "connected") {
                connected = true;
                break;
            }
        }

        if (mode === "bluetooth")
            return connected ? "󰂱" : "󰂯";
        if (mode === "ethernet")
            return connected ? "󰈁" : "󰈀";
        // wifi
        if (!Services.NetworkState.wifiEnabled)
            return "󰤭";
        return connected ? "󰤨" : "󰤫";
    }

    Rectangle {
        id: sigilBg
        width: 32
        height: 32
        radius: 8
        anchors.centerIn: parent
        color: Services.NetworkState.panelOpen ? Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, 0.16) : Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, sigilArea.containsMouse ? 0.16 : 0.09)
        border.width: 1
        border.color: Services.NetworkState.panelOpen ? Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, 0.5) : Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, sigilArea.containsMouse ? 0.48 : 0.28)
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
            text: sigil._icon
            color: Services.NetworkState.panelOpen ? Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, 1) : Qt.rgba(sigil.pathwayColor.r, sigil.pathwayColor.g, sigil.pathwayColor.b, sigilArea.containsMouse ? 0.42 : 0.25)
            font {
                family: Theme.fontMono
                pixelSize: 14
            }
            Behavior on color {
                ColorAnimation {
                    duration: Theme.animDurationFast
                }
            }
        }
    }

    MouseArea {
        id: sigilArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Services.NetworkState.panelOpen = !Services.NetworkState.panelOpen
    }
}
