import QtQuick
import "../../core"
import "../../components"

// ── MediaPopout ──────────────────────────────────────────────
// Daily media controls: metadata, progress, previous/play/next.
// Services: mpris (injected).

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var mpris: services.mpris ?? null
    readonly property var track: mpris ? mpris.nowPlaying : null
    readonly property string title: settings.title ?? "Gramophone"

    width: 340
    spacing: Theme.metrics.space.md

    Text {
        text: root.title
        color: Theme.colors.fg.primary
        font.family: Theme.typography.families.display
        font.pointSize: Theme.typography.sizes.heading
    }

    Row {
        width: parent.width
        spacing: Theme.metrics.space.md

        Rectangle {
            width: 72
            height: 72
            radius: Theme.metrics.radius.medium
            color: Theme.colors.bg.elevated
            border.width: 1
            border.color: Theme.colors.bg.surface1

            Image {
                visible: root.track && root.track.artUrl.length > 0
                anchors.fill: parent
                anchors.margins: 1
                source: root.track ? root.track.artUrl : ""
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }

            Icon {
                visible: !root.track || root.track.artUrl.length === 0
                anchors.centerIn: parent
                name: "music"
                size: 26
                color: Theme.colors.fg.subtle
            }
        }

        Column {
            width: parent.width - 72 - Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                width: parent.width
                text: root.track ? root.track.title : "No active player"
                color: Theme.colors.fg.primary
                elide: Text.ElideRight
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
                font.weight: Theme.typography.weights.medium
            }

            Text {
                width: parent.width
                text: root.track ? root.track.artist : "Start a media app to bind the record."
                color: Theme.colors.fg.muted
                elide: Text.ElideRight
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }

            Text {
                width: parent.width
                visible: root.track !== null && root.track.identity.length > 0
                text: root.track ? root.track.identity : ""
                color: Theme.colors.fg.subtle
                elide: Text.ElideRight
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }

    Rectangle {
        id: progressTrack
        visible: root.track !== null && root.track.canSeek
        width: parent.width
        height: 8
        radius: 4
        color: Theme.colors.bg.surface1

        readonly property real progress: root.track && root.track.length > 0
            ? Math.max(0, Math.min(1, root.track.position / root.track.length))
            : 0

        Rectangle {
            width: progressTrack.width * progressTrack.progress
            height: parent.height
            radius: parent.radius
            color: Theme.colors.accent.primary

            Behavior on width {
                MotionAnim {
                    spec: Motion.stateChange
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            onPressed: mouse => root.mpris.seekFraction(mouse.x / progressTrack.width)
            onPositionChanged: mouse => {
                if (pressed)
                    root.mpris.seekFraction(mouse.x / progressTrack.width);
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.metrics.space.lg

        component ControlIcon: Icon {
            property bool enabledControl: false
            signal activated()

            size: 24
            color: enabledControl ? Theme.colors.accent.primary : Theme.colors.fg.subtle

            MouseArea {
                anchors.fill: parent
                anchors.margins: -Theme.metrics.space.sm
                enabled: parent.enabledControl
                onClicked: parent.activated()
            }
        }

        ControlIcon {
            name: "previous"
            enabledControl: root.track !== null && root.track.canPrevious
            onActivated: root.mpris.previous()
        }
        ControlIcon {
            name: root.track && root.track.isPlaying ? "pause" : "play"
            enabledControl: root.track !== null && root.track.canToggle
            onActivated: root.mpris.toggle()
        }
        ControlIcon {
            name: "next"
            enabledControl: root.track !== null && root.track.canNext
            onActivated: root.mpris.next()
        }
    }
}
