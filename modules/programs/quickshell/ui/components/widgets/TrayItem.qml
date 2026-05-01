import QtQuick
import QtQuick.Effects
import Quickshell.Services.SystemTray
import "../.."
import ".." as Components

Item {
    id: trayItem

    property var item: null

    width: 34
    height: 34

    // ── External data ────────────────────────────────────────
    property var pathwayData: []
    property int activeWorkspace: 1

    // ── State ────────────────────────────────────────────────
    property bool isHovered: false
    property bool isActive: item ? item.status === Status.Active : false
    property bool needsAttention: item ? item.status === Status.NeedsAttention : false
    property color pathwayColor: {
        const activeWs = String(activeWorkspace);
        for (let i = 0; i < pathwayData.length; i++) {
            if (String(pathwayData[i].workspace) === activeWs) {
                return Qt.color(pathwayData[i].color);
            }
        }
        return Theme.accent;
    }

    // ── Hover scale animation ────────────────────────────────
    property real hoverScale: 1.0

    Behavior on hoverScale {
        NumberAnimation {
            duration: Theme.animDurationFast
            easing.type: Easing.OutQuad
        }
    }

    // ── Container frame (brass instrument socket) ────────────
    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 8
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(trayItem.pathwayColor.r, trayItem.pathwayColor.g, trayItem.pathwayColor.b, isHovered ? 0.4 : 0.2)
        scale: trayItem.hoverScale

        // Subtle radial gradient background
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(trayItem.pathwayColor.r, trayItem.pathwayColor.g, trayItem.pathwayColor.b, isHovered ? 0.1 : 0.04)
                }
                GradientStop {
                    position: 1.0
                    color: "transparent"
                }
            }
        }

        // ── Icon (normalized, desaturated) ───────────────────
        Image {
            id: iconImage
            anchors.centerIn: parent
            width: 20
            height: 20
            source: item ? item.icon : ""
            sourceSize: Qt.size(20, 20)
            smooth: true
            layer.enabled: true
            layer.effect: MultiEffect {
                saturation: -0.4
                brightness: isHovered ? 0.0 : -0.1
                contrast: 0.1
            }
            opacity: isHovered ? 1.0 : 0.8
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animDurationFast
                }
            }
        }
    }

    // ── Glow (active / attention) ────────────────────────────
    Rectangle {
        visible: trayItem.needsAttention || trayItem.isActive
        anchors.centerIn: parent
        width: frame.width + 4
        height: frame.height + 4
        radius: 10
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(trayItem.needsAttention ? 0.64 : 0.75, trayItem.needsAttention ? 0.35 : 0.64, trayItem.needsAttention ? 0.35 : 0.43, 0.25)
        opacity: trayItem.isHovered ? 0.8 : 0.4
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
            }
        }
    }

    // ── Tooltip ──────────────────────────────────────────────
    Components.RitualTooltip {
        id: tooltip
        text: item ? (item.tooltipTitle || item.title || item.id) : ""
        visible: trayItem.isHovered && text !== ""
    }

    // ── Mouse interaction ────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onEntered: {
            trayItem.isHovered = true;
            trayItem.hoverScale = 1.06;
        }
        onExited: {
            trayItem.isHovered = false;
            trayItem.hoverScale = 1.0;
        }
        onClicked: function (mouse) {
            if (mouse.button === Qt.LeftButton) {
                if (item.onlyMenu && item.hasMenu) {
                    item.display(trayItem, mouse.x, mouse.y);
                } else {
                    item.activate();
                }
            } else if (mouse.button === Qt.RightButton) {
                if (item.hasMenu) {
                    item.display(trayItem, mouse.x, mouse.y);
                } else {
                    item.secondaryActivate();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                item.secondaryActivate();
            }
        }
        onWheel: function (wheel) {
            item.scroll(wheel.angleDelta.y, false);
        }
    }
}
