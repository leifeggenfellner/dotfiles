import QtQuick
import Quickshell
import "../../core"

// ── ClockGlance ───────────────────────────────────────────────
// Time + optional date. settings: { showDate: bool; layout:
// "stacked" | "inline" } — inline puts the date beside the time for
// shallow bars (the rail, D-063).
// No services; SystemClock is Quickshell-native (no timers here).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property bool showDate: settings.showDate ?? true
    readonly property bool stacked: (settings.layout ?? "stacked") === "stacked"

    implicitWidth: column.width
    implicitHeight: Theme.metrics.bar.height

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Grid {
        id: column
        anchors.verticalCenter: parent.verticalCenter
        columns: root.stacked ? 1 : 2
        columnSpacing: Theme.metrics.space.sm
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter

        Text {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            color: Theme.colors.fg.primary
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.bar + 2
        }
        Text {
            visible: root.showDate
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }
}
