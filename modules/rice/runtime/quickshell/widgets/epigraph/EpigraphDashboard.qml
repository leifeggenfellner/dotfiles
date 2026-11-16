import Quickshell
import QtQuick
import "../../core"

// ── EpigraphDashboard ────────────────────────────────────────
// Generic dashboard flavor text. Themes provide lines through
// settings; themes that do not get neutral Observatory copy.
// settings.skyLines.<condition> (D-046) replaces the lines while that
// sky condition holds (first active condition with lines wins).

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var skyLines: {
        const sets = settings.skyLines ?? {};
        for (const c of ShellState.skyConditions)
            if (Array.isArray(sets[c]) && sets[c].length > 0)
                return sets[c];
        return null;
    }
    readonly property var lines: skyLines ?? settings.lines ?? ["A quiet overview of the machine."]
    readonly property int lineIndex: lines.length > 0 ? Math.abs(clock.date.getDate() - 1) % lines.length : 0

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
