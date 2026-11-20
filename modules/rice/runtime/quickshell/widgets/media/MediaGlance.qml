import QtQuick
import "../../core"
import "../../components"

// ── MediaGlance ──────────────────────────────────────────────
// Compact MPRIS status for the bar. Services: mpris (injected).
// settings (D-064):
//   hideIdle  collapse to nothing while no track is loaded
//   disc      keep the `music` icon and turn it while playing, only
//             while the ambient governor runs (never on battery)

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var mpris: services.mpris ?? null
    readonly property var track: mpris ? mpris.nowPlaying : null
    readonly property string idleTitle: settings.idleTitle ?? "Gramophone"
    readonly property int maxTitleWidth: settings.maxTitleWidth ?? 170
    readonly property bool hidden: (settings.hideIdle ?? false) && track === null
    readonly property bool disc: settings.disc ?? false
    readonly property bool playing: track !== null && track.isPlaying

    visible: !hidden
    implicitWidth: hidden ? 0 : row.width
    implicitHeight: Theme.metrics.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.sm

        Icon {
            id: stateIcon
            anchors.verticalCenter: parent.verticalCenter
            name: root.playing && !root.disc ? "pause" : "music"
            color: root.track ? Theme.colors.accent.primary : Theme.colors.fg.subtle

            RotationAnimator on rotation {
                running: root.disc && root.playing && ShellState.ambientActive && Motion.enabled
                from: 0
                to: 360
                loops: Animation.Infinite
                duration: Motion.revolution.duration
                easing.type: Motion.revolution.easing
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.track !== null && root.track.canToggle
                onClicked: root.mpris.toggle()
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.maxTitleWidth)
            text: root.track ? root.track.title : root.idleTitle
            color: root.track ? Theme.colors.fg.muted : Theme.colors.fg.subtle
            elide: Text.ElideRight
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }
}
