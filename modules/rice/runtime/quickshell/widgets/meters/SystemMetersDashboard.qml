import QtQuick
import "../../core"

// ── SystemMetersDashboard ────────────────────────────────────
// Dashboard vitals panel. Services: systemStats (injected).
// Settings schema:
//   labels.{cpu,memory,temperature,disk} = { title; plain }
//   colors.{cpu,memory,temperature,disk}; danger thresholds.

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var stats: services.systemStats ?? null
    readonly property var labels: settings.labels ?? ({})
    readonly property var colors: settings.colors ?? ({})
    readonly property var danger: settings.danger ?? ({})
    readonly property color dangerColor: settings.corruptionColor ?? Theme.colors.state.danger

    width: 672
    spacing: Theme.metrics.space.md

    component MeterCard: Rectangle {
        required property string title
        required property string plain
        required property string valueText
        required property real value
        required property color fillColor
        property bool danger: false

        width: (root.width - Theme.metrics.space.md) / 2
        height: 112
        radius: Theme.metrics.radius.medium
        color: Theme.colors.bg.elevated
        border.width: danger ? 2 : 1
        border.color: danger ? root.dangerColor : Theme.colors.bg.surface1

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.metrics.space.md
            spacing: Theme.metrics.space.sm

            Row {
                width: parent.width
                spacing: Theme.metrics.space.sm

                Text {
                    width: parent.width - valueLabel.width - Theme.metrics.space.sm
                    text: title + (plain.length > 0 ? " · " + plain : "")
                    color: Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                    elide: Text.ElideRight
                }

                Text {
                    id: valueLabel
                    text: valueText
                    color: danger ? root.dangerColor : Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.body
                }
            }

            Rectangle {
                width: parent.width
                height: 12
                radius: 6
                color: Theme.colors.bg.sunken

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, value))
                    height: parent.height
                    radius: parent.radius
                    color: danger ? root.dangerColor : fillColor

                    Behavior on width {
                        MotionAnim {
                            spec: Motion.stateChange
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                }
            }

            Text {
                text: danger ? (settings.dangerText ?? "threshold crossed") : (settings.calmText ?? "nominal")
                color: danger ? root.dangerColor : Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }

    Grid {
        columns: 2
        spacing: Theme.metrics.space.md

        MeterCard {
            title: root.labels.cpu?.title ?? "CPU"
            plain: root.labels.cpu?.plain ?? "load"
            value: root.stats ? root.stats.cpuLoad : 0
            valueText: Math.round(value * 100) + "%"
            fillColor: root.colors.cpu ?? Theme.colors.accent.primary
            danger: value >= (root.danger.cpu ?? 0.85)
        }

        MeterCard {
            title: root.labels.memory?.title ?? "Memory"
            plain: root.labels.memory?.plain ?? "RAM"
            value: root.stats ? root.stats.memoryPercent : 0
            valueText: Math.round(value * 100) + "%"
            fillColor: root.colors.memory ?? Theme.colors.accent.secondary
            danger: value >= (root.danger.memory ?? 0.9)
        }

        MeterCard {
            title: root.labels.temperature?.title ?? "Temperature"
            plain: root.labels.temperature?.plain ?? "thermal"
            value: root.stats && root.stats.temperatureC >= 0 ? root.stats.temperatureC / (root.danger.temperatureMax ?? 100) : 0
            valueText: root.stats && root.stats.temperatureC >= 0 ? Math.round(root.stats.temperatureC) + "°C" : "n/a"
            fillColor: root.colors.temperature ?? Theme.colors.state.warn
            danger: root.stats && root.stats.temperatureC >= (root.danger.temperature ?? 85)
        }

        MeterCard {
            title: root.labels.disk?.title ?? "Disk"
            plain: root.labels.disk?.plain ?? "/"
            value: root.stats ? root.stats.diskPercent : 0
            valueText: Math.round(value * 100) + "%"
            fillColor: root.colors.disk ?? Theme.colors.state.info
            danger: value >= (root.danger.disk ?? 0.9)
        }
    }

    Text {
        visible: root.stats !== null && root.stats.error.length > 0
        width: parent.width
        text: root.stats ? root.stats.error : ""
        color: Theme.colors.state.danger
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.small
    }
}
