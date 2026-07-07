import QtQuick
import "../../core"
import "../../components"

// ── MediaGlance ──────────────────────────────────────────────
// Compact MPRIS status for the bar. Services: mpris (injected).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var mpris: services.mpris ?? null
    readonly property var track: mpris ? mpris.nowPlaying : null
    readonly property string idleTitle: settings.idleTitle ?? "Gramophone"
    readonly property int maxTitleWidth: settings.maxTitleWidth ?? 170

    implicitWidth: row.width
    implicitHeight: Theme.metrics.bar.height

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.sm

        Icon {
            id: stateIcon
            anchors.verticalCenter: parent.verticalCenter
            name: root.track && root.track.isPlaying ? "pause" : "music"
            color: root.track ? Theme.colors.accent.primary : Theme.colors.fg.subtle

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
