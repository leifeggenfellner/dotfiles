import QtQuick
import "../core"

// ── SignalBars ────────────────────────────────────────────────
// Four rising bars, lit up to `level` [0..1].

Row {
    id: root

    property real level: 0
    property int size: Theme.typography.sizes.body
    property color color: Theme.colors.fg.muted
    property color dim: Theme.colors.bg.surface2

    readonly property int lit: level <= 0 ? 0 : Math.max(1, Math.ceil(level * 4))

    spacing: Math.max(1, Math.round(size / 9))
    height: size

    Repeater {
        model: 4
        Rectangle {
            required property int index
            anchors.bottom: parent.bottom
            width: Math.max(2, Math.round(root.size / 5))
            height: root.size * (index + 1) / 4
            radius: width / 2
            color: index < root.lit ? root.color : root.dim
        }
    }
}
