import QtQuick
import "../../core"
import "../../components"

// ── SystemClusterGlance ───────────────────────────────────────
// Compact system status: network, audio, battery. Read-only glance;
// the cluster popout (details + controls) is Phase 8b.
// Services: network, audio, power (injected).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var net: services.network ?? null
    readonly property var audio: services.audio ?? null
    readonly property var power: services.power ?? null

    implicitWidth: row.width
    implicitHeight: Theme.metrics.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.md

        Icon {
            visible: root.net !== null
            anchors.verticalCenter: parent.verticalCenter
            name: !root.net || !root.net.connected ? "wifi-off"
                : (root.net.activeType === "ethernet" ? "ethernet" : "wifi")
            color: root.net && root.net.connected ? Theme.colors.fg.muted : Theme.colors.state.warn
        }

        Icon {
            visible: root.audio !== null
            anchors.verticalCenter: parent.verticalCenter
            name: root.audio && root.audio.muted ? "volume-muted" : "volume"
            color: root.audio && root.audio.muted ? Theme.colors.fg.subtle : Theme.colors.fg.muted
        }

        Row {
            visible: root.power !== null && root.power.available
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.power && root.power.charging ? "battery-charging" : "battery"
                color: {
                    if (!root.power)
                        return Theme.colors.fg.muted;
                    if (root.power.charging)
                        return Theme.colors.state.ok;
                    return root.power.batteryPercent < 0.2 ? Theme.colors.state.danger : Theme.colors.fg.muted;
                }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.power ? Math.round(root.power.batteryPercent * 100) + "%" : ""
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
