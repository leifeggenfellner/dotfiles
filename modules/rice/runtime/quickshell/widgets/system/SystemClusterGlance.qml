import QtQuick
import "../../core"
import "../../components"

// ── SystemClusterGlance ───────────────────────────────────────
// Compact system status: network, audio, bluetooth, battery.
// Services: network, audio, bluetooth, power (injected).
//
// Icons come from the theme's icon map (D-064): signal strength
// prefers `wifi-0`…`wifi-3` when the theme names them, and a theme
// with a `battery-ink` icon gets a vial gauge (GaugeIcon) instead of
// the battery glyph. settings:
//   bluetooth        show the bluetooth icon while the adapter is on
//   batteryGauge     { full; empty } — where they sit on the icon
//   lowBattery       level that turns the battery to danger (0.2)
//   criticalBattery  level below which it pulses (0 = never)

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var net: services.network ?? null
    readonly property var audio: services.audio ?? null
    readonly property var bt: services.bluetooth ?? null
    readonly property var power: services.power ?? null

    readonly property real lowBattery: settings.lowBattery ?? 0.2
    readonly property real criticalBattery: settings.criticalBattery ?? 0
    readonly property var gauge: settings.batteryGauge ?? ({})
    readonly property bool low: power !== null && !power.charging && power.batteryPercent <= lowBattery
    readonly property bool critical: power !== null && power.available && !power.charging && power.batteryPercent <= criticalBattery

    readonly property string netIcon: {
        if (!net || !net.connected)
            return "wifi-off";
        if (net.activeType === "ethernet")
            return "ethernet";
        const step = "wifi-" + Math.min(3, Math.floor(net.strength * 4));
        return Theme.hasIcon(step) ? step : "wifi";
    }

    implicitWidth: row.width
    implicitHeight: Theme.metrics.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.md

        Icon {
            visible: root.net !== null
            anchors.verticalCenter: parent.verticalCenter
            name: root.netIcon
            color: root.net && root.net.connected ? Theme.colors.fg.muted : Theme.colors.state.warn
        }

        Icon {
            visible: root.audio !== null
            anchors.verticalCenter: parent.verticalCenter
            name: root.audio && root.audio.muted ? "volume-muted" : "volume"
            color: root.audio && root.audio.muted ? Theme.colors.fg.subtle : Theme.colors.fg.muted
        }

        Icon {
            visible: (root.settings.bluetooth ?? false) && root.bt !== null && root.bt.powered
            anchors.verticalCenter: parent.verticalCenter
            name: "bluetooth"
            color: Theme.colors.fg.muted
        }

        Row {
            id: battery

            visible: root.power !== null && root.power.available
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            SequentialAnimation on opacity {
                running: root.critical && Motion.enabled
                loops: Animation.Infinite
                onRunningChanged: if (!running)
                    battery.opacity = 1

                MotionAnim {
                    to: 0.35
                    spec: Motion.alarm
                }
                MotionAnim {
                    to: 1
                    spec: Motion.alarm
                }
            }

            GaugeIcon {
                visible: Theme.hasIcon("battery-ink")
                anchors.verticalCenter: parent.verticalCenter
                glass: root.power && root.power.charging ? "battery-charging" : "battery"
                ink: root.low && Theme.hasIcon("battery-ink-low") ? "battery-ink-low" : "battery-ink"
                level: root.power ? root.power.batteryPercent : 0
                full: root.gauge.full ?? 0
                empty: root.gauge.empty ?? 1
            }

            Icon {
                visible: !Theme.hasIcon("battery-ink")
                anchors.verticalCenter: parent.verticalCenter
                name: root.power && root.power.charging ? "battery-charging" : "battery"
                color: {
                    if (!root.power)
                        return Theme.colors.fg.muted;
                    if (root.power.charging)
                        return Theme.colors.state.ok;
                    return root.low ? Theme.colors.state.danger : Theme.colors.fg.muted;
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
