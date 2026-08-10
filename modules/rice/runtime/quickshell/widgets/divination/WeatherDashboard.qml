import QtQuick
import "../../core"
import "../../components"

// ── WeatherDashboard ─────────────────────────────────────────
// Weather panel for the Observatory. Services: weather.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var weather: services.weather ?? null
    readonly property string title: settings.title ?? "Weather"
    readonly property string unavailableText: settings.unavailableText ?? "Weather is veiled."
    readonly property bool hasWeather: weather !== null && weather.available
    readonly property bool compact: width < 430
    readonly property int iconSize: compact ? 56 : 64

    implicitHeight: (compact ? compactLayout.implicitHeight : wideLayout.implicitHeight)
    height: implicitHeight

    Row {
        id: wideLayout

        anchors.fill: parent
        spacing: Theme.metrics.space.lg
        visible: !root.compact

        Rectangle {
            width: root.iconSize
            height: root.iconSize
            radius: width / 2
            color: Theme.colors.bg.sunken
            border.width: 1
            border.color: Theme.colors.accent.secondary

            Icon {
                anchors.centerIn: parent
                name: "weather"
                size: Theme.typography.sizes.heading + 4
                color: Theme.colors.accent.secondary
            }
        }

        Column {
            width: parent.width - root.iconSize - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                width: parent.width
                text: root.hasWeather ? root.weather.condition + (root.weather.location.length > 0 ? " · " + root.weather.location : "") : (root.weather && root.weather.error.length > 0 ? root.weather.error : root.unavailableText)
                color: root.hasWeather ? Theme.colors.fg.muted : Theme.colors.fg.subtle
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }

            Flow {
                spacing: Theme.metrics.space.lg
                width: parent.width

                Text {
                    text: root.hasWeather ? Math.round(root.weather.temperatureC) + "°C" : "n/a"
                    color: Theme.colors.accent.primary
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.heading
                }
                Text {
                    text: root.hasWeather ? "feels " + Math.round(root.weather.feelsLikeC) + "°C" : "temperature"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
                Text {
                    text: root.hasWeather ? "humidity " + root.weather.humidity + "%" : "humidity n/a"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
                Text {
                    text: root.hasWeather ? "wind " + Math.round(root.weather.windKph) + " km/h" : "wind n/a"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }

    Column {
        id: compactLayout

        width: parent.width
        spacing: Theme.metrics.space.md
        visible: root.compact

        Rectangle {
            width: root.iconSize
            height: root.iconSize
            anchors.horizontalCenter: parent.horizontalCenter
            radius: width / 2
            color: Theme.colors.bg.sunken
            border.width: 1
            border.color: Theme.colors.accent.secondary

            Icon {
                anchors.centerIn: parent
                name: "weather"
                size: Theme.typography.sizes.heading + 4
                color: Theme.colors.accent.secondary
            }
        }

        Text {
            width: parent.width
            text: root.hasWeather ? root.weather.condition + (root.weather.location.length > 0 ? " · " + root.weather.location : "") : (root.weather && root.weather.error.length > 0 ? root.weather.error : root.unavailableText)
            color: root.hasWeather ? Theme.colors.fg.muted : Theme.colors.fg.subtle
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.body
        }

        Flow {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: Theme.metrics.space.md

            Text {
                text: root.hasWeather ? Math.round(root.weather.temperatureC) + "°C" : "n/a"
                color: Theme.colors.accent.primary
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.heading
            }
            Text {
                text: root.hasWeather ? "feels " + Math.round(root.weather.feelsLikeC) + "°C" : "temperature"
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }
            Text {
                text: root.hasWeather ? "humidity " + root.weather.humidity + "%" : "humidity n/a"
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }
            Text {
                text: root.hasWeather ? "wind " + Math.round(root.weather.windKph) + " km/h" : "wind n/a"
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
