import QtQuick
import "../../core"
import "../../components"

// ── CalendarDashboard ────────────────────────────────────────
// Calendar and moon panel for the Observatory. Services: weather
// supplies the local lunar phase even when weather is unavailable.

Rectangle {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var weather: services.weather ?? null
    readonly property date now: weather ? weather.now : localClock.now
    readonly property var moonPhase: weather ? weather.moonPhase : ({
            name: "unknown",
            illumination: 0,
            icon: "moon"
        })
    readonly property string title: settings.title ?? "Calendar"
    readonly property string moonLabel: settings.moonLabel ?? "moon"
    readonly property var secret: settings.secret ?? ({})

    width: 672
    height: 156
    radius: Theme.metrics.radius.medium
    color: Theme.colors.bg.base
    border.width: 1
    border.color: Theme.colors.bg.surface1

    QtObject {
        id: localClock
        property date now: new Date()
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: localClock.now = new Date()
    }

    function revealSecret() {
        if (secret.enabled !== true)
            return;
        Sound.play(secret.sound ?? "");
        ShellState.triggerFlavorEvent(secret.text ?? "", secret.event ?? "calendarSecret", secret.surge ?? true);
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: root.revealSecret()
    }

    Row {
        anchors.fill: parent
        anchors.margins: Theme.metrics.space.lg
        spacing: Theme.metrics.space.lg

        Column {
            width: 250
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                text: root.title
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.heading
            }
            Text {
                text: Qt.formatDate(root.now, "dddd")
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
            Text {
                text: Qt.formatDate(root.now, "d MMMM yyyy")
                color: Theme.colors.accent.primary
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.heading
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Theme.colors.bg.surface1
        }

        Row {
            width: parent.width - 250 - 1 - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.lg

            Rectangle {
                width: 76
                height: 76
                radius: width / 2
                color: Theme.colors.bg.sunken
                border.width: 1
                border.color: Theme.colors.accent.secondary

                Icon {
                    anchors.centerIn: parent
                    name: root.moonPhase.icon ?? "moon"
                    size: Theme.typography.sizes.heading + 8
                    color: Theme.colors.accent.secondary
                }
            }

            Column {
                width: parent.width - 76 - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.metrics.space.xs

                Text {
                    text: root.moonLabel
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.small + 1
                }
                Text {
                    width: parent.width
                    text: root.moonPhase.name
                    color: Theme.colors.fg.primary
                    elide: Text.ElideRight
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.heading
                }
                Text {
                    text: Math.round((root.moonPhase.illumination ?? 0) * 100) + "% illuminated"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }
}
