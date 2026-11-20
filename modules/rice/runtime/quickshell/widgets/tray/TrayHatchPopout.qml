import QtQuick
import "../../core"
import "../../components"

// ── TrayHatchPopout ───────────────────────────────────────────
// The open hatch (D-064): every tray item, menus app-native (D-036).
// Services: tray (injected).

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    width: 220
    spacing: Theme.metrics.space.xs

    Text {
        text: root.settings.title ?? "Tray"
        color: Theme.colors.fg.subtle
        font.family: Theme.typography.families.sans
        font.pointSize: Theme.typography.sizes.small
    }

    TrayGrid {
        width: parent.width
        tray: root.services.tray ?? null
    }
}
