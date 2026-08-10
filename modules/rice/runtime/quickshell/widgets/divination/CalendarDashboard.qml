import QtQuick
import "../../core"
import "../../components"

// ── CalendarDashboard ────────────────────────────────────────
// Calendar and moon panel for the Observatory. Services: weather
// supplies the local lunar phase even when weather is unavailable.

Item {
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
    readonly property bool compact: width < 520
    readonly property int moonIconSize: compact ? 64 : 76

    implicitHeight: compact ? compactLayout.implicitHeight : wideLayout.implicitHeight
    height: implicitHeight

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
        id: wideLayout

        anchors.fill: parent
        spacing: Theme.metrics.space.lg
        visible: !root.compact

        Column {
            readonly property int availableTextWidth: parent.width - parent.spacing * 2 - separator.width - root.moonIconSize - Theme.metrics.space.lg

            width: Math.min(280, Math.max(190, availableTextWidth * 0.46))
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                text: Qt.formatDate(root.now, "dddd")
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
            Text {
                width: parent.width
                text: Qt.formatDate(root.now, "d MMMM yyyy")
                color: Theme.colors.accent.primary
                wrapMode: Text.WordWrap
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.heading
            }
        }

        Rectangle {
            id: separator

            width: 1
            height: parent.height
            color: Theme.colors.bg.surface1
        }

        Row {
            width: parent.width - x
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.lg

            Rectangle {
                width: root.moonIconSize
                height: root.moonIconSize
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
                width: parent.width - root.moonIconSize - parent.spacing
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
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
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

    Column {
        id: compactLayout

        width: parent.width
        spacing: Theme.metrics.space.md
        visible: root.compact

        Column {
            width: parent.width
            spacing: Theme.metrics.space.xs

            Text {
                width: parent.width
                text: Qt.formatDate(root.now, "dddd")
                color: Theme.colors.fg.muted
                horizontalAlignment: Text.AlignHCenter
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
            Text {
                width: parent.width
                text: Qt.formatDate(root.now, "d MMMM yyyy")
                color: Theme.colors.accent.primary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.heading
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.colors.bg.surface1
        }

        Row {
            width: parent.width
            spacing: Theme.metrics.space.md

            Rectangle {
                width: root.moonIconSize
                height: root.moonIconSize
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
                width: parent.width - root.moonIconSize - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.metrics.space.xs

                Text {
                    width: parent.width
                    text: root.moonLabel
                    color: Theme.colors.fg.subtle
                    wrapMode: Text.WordWrap
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.small + 1
                }
                Text {
                    width: parent.width
                    text: root.moonPhase.name
                    color: Theme.colors.fg.primary
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.heading
                }
                Text {
                    width: parent.width
                    text: Math.round((root.moonPhase.illumination ?? 0) * 100) + "% illuminated"
                    color: Theme.colors.fg.subtle
                    wrapMode: Text.WordWrap
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }
}
