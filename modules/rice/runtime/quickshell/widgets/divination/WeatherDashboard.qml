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

    width: 672
    height: 96

    Row {
        anchors.fill: parent
        spacing: Theme.metrics.space.lg

        Rectangle {
            width: 64
            height: 64
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
            width: parent.width - 72 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                width: parent.width
                text: root.hasWeather ? root.weather.condition + (root.weather.location.length > 0 ? " · " + root.weather.location : "") : (root.weather && root.weather.error.length > 0 ? root.weather.error : root.unavailableText)
                color: root.hasWeather ? Theme.colors.fg.muted : Theme.colors.fg.subtle
                elide: Text.ElideRight
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }

            Row {
                spacing: Theme.metrics.space.lg

                Text {
                    text: root.hasWeather ? Math.round(root.weather.temperatureC) + "°C" : "n/a"
                    color: Theme.colors.accent.primary
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.heading
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hasWeather ? "feels " + Math.round(root.weather.feelsLikeC) + "°C" : "temperature"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hasWeather ? "humidity " + root.weather.humidity + "%" : "humidity n/a"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.hasWeather ? "wind " + Math.round(root.weather.windKph) + " km/h" : "wind n/a"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }
}
