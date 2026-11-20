import QtQuick
import "../core"

// ── GaugeIcon ─────────────────────────────────────────────────
// A two-layer theme icon whose fill shows a level (D-064): `ink` is
// drawn only below the level line, `glass` on top. `full` and `empty`
// are where those levels sit, as fractions of the icon's height,
// so the line tracks the drawn vessel rather than the whole box.
//
//   GaugeIcon { glass: "battery"; ink: "battery-ink"; level: 0.6 }

Item {
    id: root

    required property string glass
    required property string ink
    property real level: 0
    property real full: 0
    property real empty: 1
    property int size: Theme.typography.sizes.icon

    readonly property real clamped: Math.max(0, Math.min(1, level))
    readonly property real line: size * (empty - clamped * (empty - full))

    implicitWidth: size
    implicitHeight: size

    Item {
        y: root.line
        width: root.size
        height: root.size - root.line
        clip: true

        Image {
            y: -root.line
            width: root.size
            height: root.size
            source: Theme.iconUrl(Theme.icon(root.ink))
            sourceSize.width: root.size * 2
            sourceSize.height: root.size * 2
            smooth: true
        }
    }

    Icon {
        name: root.glass
        size: root.size
    }
}
