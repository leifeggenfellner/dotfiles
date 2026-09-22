import QtQuick
import "../../core"
import "../../components"

// Compact monitor-control status. Services: monitorControl, hypr (injected).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var monitorControl: services.monitorControl ?? null
    readonly property var hypr: services.hypr ?? null
    readonly property string profile: monitorControl?.activeProfile ?? ""
    readonly property string label: profile.length > 0 ? profile.replace(/_/g, " ") : (monitorControl?.available ? "detecting" : "unavailable")

    implicitWidth: row.width
    implicitHeight: Theme.metrics.bar.height

    Connections {
        target: root.hypr
        ignoreUnknownSignals: true
        function onMonitorsRevisionChanged() {
            root.monitorControl?.refresh();
        }
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.sm

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: root.monitorControl?.busy ? "refresh" : "monitor"
            color: {
                if (!root.monitorControl?.available)
                    return Theme.colors.state.warn;
                if (root.monitorControl.error.length > 0)
                    return Theme.colors.state.danger;
                return Theme.colors.accent.primary;
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, settings.maxLabelWidth ?? 120)
            text: root.label
            color: root.monitorControl?.available ? Theme.colors.fg.muted : Theme.colors.fg.subtle
            elide: Text.ElideRight
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }
}
