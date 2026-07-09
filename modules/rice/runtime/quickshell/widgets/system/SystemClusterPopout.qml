import QtQuick
import "../../core"
import "../../components"

// ── SystemClusterPopout ───────────────────────────────────────
// Controls behind the system glance: volume, wifi, bluetooth, tray.
// Services: network, audio, bluetooth, tray (injected).
// Tray lives here, not in the bar (L-009); left click activates,
// right click opens the app-native menu. Secured new networks expand
// an inline password prompt.

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var net: services.network ?? null
    readonly property var audio: services.audio ?? null
    readonly property var bt: services.bluetooth ?? null
    readonly property var tray: services.tray ?? null

    width: 340
    spacing: Theme.metrics.space.md

    function trayMenuPosition(itemNode) {
        const p = itemNode.mapToItem(null, itemNode.width, itemNode.height);
        return {
            x: Math.round(p.x),
            y: Math.round(p.y)
        };
    }

    function openTrayMenu(item, itemNode) {
        if (!root.tray || !item || !item.hasMenu)
            return false;
        const pos = trayMenuPosition(itemNode);
        return root.tray.displayMenu(item.id, itemNode.Window.window, pos.x, pos.y);
    }

    // Popout content is created fresh on every open — drop stale
    // errors/prompts from previous interactions.
    Component.onCompleted: root.net?.clearError()

    component SectionLabel: Text {
        color: Theme.colors.fg.subtle
        font.family: Theme.typography.families.display
        font.pointSize: Theme.typography.sizes.small + 1
    }

    // ── Audio ─────────────────────────────────────────────────
    Row {
        visible: root.audio !== null
        width: parent.width
        spacing: Theme.metrics.space.md

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.audio && root.audio.muted ? "volume-muted" : "volume"
            color: root.audio && root.audio.muted ? Theme.colors.fg.subtle : Theme.colors.accent.primary

            MouseArea {
                anchors.fill: parent
                onClicked: root.audio.toggleMuted()
            }
        }

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 100
            height: 8
            radius: 4
            color: Theme.colors.bg.surface1

            Rectangle {
                width: parent.width * (root.audio ? root.audio.volume : 0)
                height: parent.height
                radius: parent.radius
                color: Theme.colors.accent.primary

                Behavior on width {
                    MotionAnim {}
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                onPressed: mouse => root.audio.setVolume(mouse.x / track.width)
                onPositionChanged: mouse => {
                    if (pressed)
                        root.audio.setVolume(Math.max(0, Math.min(1, mouse.x / track.width)));
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.audio ? Math.round(root.audio.volume * 100) + "%" : ""
            color: Theme.colors.fg.muted
            font.family: Theme.typography.families.mono
            font.pointSize: Theme.typography.sizes.small
        }
    }

    // ── Wifi ──────────────────────────────────────────────────
    Column {
        visible: root.net !== null
        width: parent.width
        spacing: Theme.metrics.space.xs

        Item {
            width: parent.width
            height: netLabel.height

            SectionLabel {
                id: netLabel
                text: "Network"
            }

            Icon {
                anchors.right: parent.right
                name: "refresh"
                size: Theme.typography.sizes.body
                color: rescanMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle

                MouseArea {
                    id: rescanMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.metrics.space.sm
                    hoverEnabled: true
                    onClicked: root.net.rescan()
                }
            }
        }

        Repeater {
            model: root.net ? root.net.networks.slice(0, 6) : []

            Column {
                id: netEntry

                required property var modelData
                readonly property bool wantsPassword: root.net !== null && root.net.passwordNeededFor.length > 0 && root.net.passwordNeededFor === modelData.ssid

                width: parent.width
                spacing: 2

                Rectangle {
                    id: netRow

                    width: parent.width
                    height: 32
                    radius: Theme.metrics.radius.small
                    color: netMouse.containsMouse ? Theme.colors.bg.elevated : (netEntry.modelData.active ? Theme.colors.bg.elevated : "transparent")

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.metrics.space.sm
                        spacing: Theme.metrics.space.sm

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: netEntry.modelData.ssid
                            color: netEntry.modelData.active ? Theme.colors.accent.primary : Theme.colors.fg.primary
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.body
                        }
                        Icon {
                            visible: netEntry.modelData.secured
                            anchors.verticalCenter: parent.verticalCenter
                            name: "lock"
                            size: Theme.typography.sizes.small
                            color: Theme.colors.fg.subtle
                        }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.metrics.space.sm
                        anchors.verticalCenter: parent.verticalCenter
                        text: netEntry.modelData.active ? "disconnect" : Math.round(netEntry.modelData.strength * 100) + "%"
                        color: netEntry.modelData.active && netMouse.containsMouse ? Theme.colors.state.warn : Theme.colors.fg.subtle
                        font.family: Theme.typography.families.mono
                        font.pointSize: Theme.typography.sizes.small
                    }

                    MouseArea {
                        id: netMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: netEntry.modelData.active ? root.net.disconnect() : root.net.connect(netEntry.modelData.ssid)
                    }
                }

                // Inline password prompt: appears when nmcli reported
                // missing secrets for THIS network.
                Rectangle {
                    visible: netEntry.wantsPassword
                    width: parent.width
                    height: 32
                    radius: Theme.metrics.radius.small
                    color: Theme.colors.bg.sunken
                    border.width: 1
                    border.color: Theme.colors.accent.primary

                    onVisibleChanged: {
                        if (visible) {
                            pwInput.text = "";
                            pwInput.forceActiveFocus();
                        }
                    }

                    TextInput {
                        id: pwInput
                        anchors.fill: parent
                        anchors.leftMargin: Theme.metrics.space.sm
                        anchors.rightMargin: Theme.metrics.space.sm
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: TextInput.Password
                        color: Theme.colors.fg.primary
                        font.family: Theme.typography.families.mono
                        font.pointSize: Theme.typography.sizes.body
                        onAccepted: {
                            if (text.length > 0)
                                root.net.connect(netEntry.modelData.ssid, text);
                        }

                        Text {
                            visible: pwInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "password · Enter to join"
                            color: Theme.colors.fg.subtle
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                        }
                    }
                }
            }
        }

        Text {
            visible: root.net !== null && root.net.error.length > 0
            width: parent.width
            text: root.net ? root.net.error : ""
            color: Theme.colors.state.danger
            wrapMode: Text.WordWrap
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }

    // ── Bluetooth ─────────────────────────────────────────────
    Column {
        visible: root.bt !== null && root.bt.available
        width: parent.width
        spacing: Theme.metrics.space.xs

        Item {
            width: parent.width
            height: btLabel.height

            SectionLabel {
                id: btLabel
                text: "Bluetooth"
            }

            Text {
                anchors.right: parent.right
                text: root.bt && root.bt.powered ? "on" : "off"
                color: btPowerMouse.containsMouse ? Theme.colors.accent.primary : (root.bt && root.bt.powered ? Theme.colors.state.ok : Theme.colors.fg.subtle)
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small

                MouseArea {
                    id: btPowerMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.metrics.space.sm
                    hoverEnabled: true
                    onClicked: root.bt.setPowered(!root.bt.powered)
                }
            }
        }

        Repeater {
            model: root.bt && root.bt.powered ? root.bt.devices : []

            Rectangle {
                id: btRow

                required property var modelData

                width: parent.width
                height: 32
                radius: Theme.metrics.radius.small
                color: btMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: btRow.modelData.name
                    color: btRow.modelData.connected ? Theme.colors.accent.primary : Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: btRow.modelData.connected ? "connected" : "connect"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }

                MouseArea {
                    id: btMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: btRow.modelData.connected ? root.bt.disconnect(btRow.modelData.address) : root.bt.connect(btRow.modelData.address)
                }
            }
        }
    }

    // ── Tray (L-009: popout only, never bar icons) ────────────
    Column {
        visible: root.tray !== null && root.tray.items.length > 0
        width: parent.width
        spacing: Theme.metrics.space.xs

        SectionLabel {
            text: "Tray"
        }

        Flow {
            width: parent.width
            spacing: Theme.metrics.space.sm

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
                                if (!root.openTrayMenu(trayItem.modelData, trayItem))
                                    root.tray.secondaryActivate(trayItem.modelData.id);
                                return;
                            }
                            if (mouse.button === Qt.MiddleButton) {
                                root.tray.secondaryActivate(trayItem.modelData.id);
                                return;
                            }
                            if (trayItem.onlyMenu)
                                root.openTrayMenu(trayItem.modelData, trayItem);
                            else
                                root.tray.activate(trayItem.modelData.id);
                        }
                        onPressAndHold: root.openTrayMenu(trayItem.modelData, trayItem)
                    }
                }
            }
        }
    }
}
