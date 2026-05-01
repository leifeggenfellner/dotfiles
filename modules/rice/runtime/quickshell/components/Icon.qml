import QtQuick
import "../core"

// ── Icon ──────────────────────────────────────────────────────
// Renders a semantic icon name via the theme's icon map: either a
// Nerd Font glyph or a theme-shipped image file, decided by the
// active theme, not the caller.
//
//   Icon { name: "terminal"; size: 22; color: Theme.colors.fg.muted }
//
// `color` tints glyphs only; file icons carry their own colors.

Item {
    id: root

    required property string name
    property int size: Theme.typography.sizes.icon
    property color color: Theme.colors.fg.muted

    readonly property string resolved: Theme.icon(name)
    readonly property bool isFile: Theme.iconIsFile(resolved)

    implicitWidth: size
    implicitHeight: size

    Text {
        visible: !root.isFile
        anchors.centerIn: parent
        text: root.isFile ? "" : root.resolved
        color: root.color
        font.family: Theme.typography.families.mono
        font.pointSize: root.size
    }

    Image {
        readonly property string url: root.isFile ? Theme.iconUrl(root.resolved) : ""
        visible: root.isFile && url.length > 0
        anchors.fill: parent
        source: url
        sourceSize.width: root.size * 2
        sourceSize.height: root.size * 2
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
}
