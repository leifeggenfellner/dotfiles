import QtQuick
import Quickshell
import "../../core"

// ── ClockGlance ───────────────────────────────────────────────
// Time + optional date. settings: { showDate: bool }.
// No services; SystemClock is Quickshell-native (no timers here).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property bool showDate: settings.showDate ?? true

    implicitWidth: column.width
    implicitHeight: Theme.metrics.bar.height

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.colors.fg.primary
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.bar + 2
        }
        Text {
            visible: root.showDate
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }
}
