import Quickshell
import QtQuick
import "../../core"

// ── EpigraphDashboard ────────────────────────────────────────
// Generic dashboard flavor text. Themes provide lines through
// settings; themes that do not get neutral Observatory copy.

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var lines: settings.lines ?? ["A quiet overview of the machine."]
    readonly property int lineIndex: lines.length > 0 ? Math.abs(clock.date.getDate() - 1) % lines.length : 0

    width: 672
    spacing: Theme.metrics.space.sm

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    Text {
        width: parent.width
        text: lines.length > 0 ? lines[lineIndex] : ""
        color: Theme.colors.fg.muted
        wrapMode: Text.WordWrap
        font.family: Theme.typography.families.sans
        font.pointSize: Theme.typography.sizes.body
    }
}
