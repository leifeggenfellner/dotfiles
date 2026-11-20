import QtQuick
import "../core"

// ── TrayGrid ──────────────────────────────────────────────────
// Every tray item as a button. `tray` is the injected tray service;
// menus stay app-native (D-036): left click activates, right click
// and long-press open the app's own menu, middle click is the
// secondary action, and menu-only items open their menu on left click.

Flow {
    id: root

    property var tray: null

    spacing: Theme.metrics.space.sm

    function menuPosition(itemNode) {
        const p = itemNode.mapToItem(null, itemNode.width, itemNode.height);
        return {
            x: Math.round(p.x),
            y: Math.round(p.y)
        };
    }

    function openMenu(item, itemNode) {
        if (!root.tray || !item || !item.hasMenu)
            return false;
        const pos = menuPosition(itemNode);
        return root.tray.displayMenu(item.id, itemNode.Window.window, pos.x, pos.y);
    }

    Repeater {
        model: root.tray ? root.tray.items : []

        Rectangle {
            id: trayItem

            required property var modelData
            readonly property bool hasMenu: modelData.hasMenu === true
            readonly property bool onlyMenu: modelData.onlyMenu === true

            width: 36
            height: 36
            radius: Theme.metrics.radius.small
            color: trayMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"
            border.width: hasMenu && trayMouse.containsMouse ? 1 : 0
            border.color: Theme.colors.accent.primary

            Image {
                anchors.centerIn: parent
                width: 22
                height: 22
                source: trayItem.modelData.icon
                sourceSize.width: 44
                sourceSize.height: 44
                fillMode: Image.PreserveAspectFit
                smooth: true
            }

            MouseArea {
                id: trayMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        if (!root.openMenu(trayItem.modelData, trayItem))
                            root.tray.secondaryActivate(trayItem.modelData.id);
                        return;
                    }
                    if (mouse.button === Qt.MiddleButton) {
                        root.tray.secondaryActivate(trayItem.modelData.id);
                        return;
                    }
                    if (trayItem.onlyMenu)
                        root.openMenu(trayItem.modelData, trayItem);
                    else
                        root.tray.activate(trayItem.modelData.id);
                }
                onPressAndHold: root.openMenu(trayItem.modelData, trayItem)
            }
        }
    }
}
