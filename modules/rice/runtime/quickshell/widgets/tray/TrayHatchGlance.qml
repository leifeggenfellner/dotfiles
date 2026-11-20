import QtQuick
import QtQuick.Effects
import "../../core"
import "../../components"

// ── TrayHatchGlance ───────────────────────────────────────────
// The tray hatch (D-064): a small compartment showing the first
// `maxInline` tray icons, with a count of the rest. `tone = "sepia"`
// mutes app colours toward the theme until hovered. Collapses when
// the tray is empty. A click opens the popout with every item.
// Services: tray (injected). Off unless the theme enables it.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var tray: services.tray ?? null
    readonly property var items: tray ? tray.items : []
    readonly property int maxInline: settings.maxInline ?? 3
    readonly property bool toned: (settings.tone ?? "none") === "sepia" && !hover.containsMouse
    readonly property int overflow: Math.max(0, items.length - maxInline)

    visible: items.length > 0
    implicitWidth: items.length > 0 ? row.width + divider.anchors.leftMargin + divider.width : 0
    implicitHeight: Theme.metrics.bar.height

    HoverHandler {
        id: hover
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.sm

        Repeater {
            model: root.items.slice(0, root.maxInline)

            Image {
                required property var modelData

                anchors.verticalCenter: parent.verticalCenter
                width: Theme.typography.sizes.icon
                height: width
                source: modelData.icon
                sourceSize.width: width * 2
                sourceSize.height: height * 2
                fillMode: Image.PreserveAspectFit
                smooth: true
                layer.enabled: root.toned
                layer.effect: MultiEffect {
                    saturation: -1
                    colorization: 0.45
                    colorizationColor: Theme.colors.accent.primary
                    brightness: -0.1
                }
            }
        }

        Text {
            visible: root.overflow > 0
            anchors.verticalCenter: parent.verticalCenter
            text: "+" + root.overflow
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.mono
            font.pointSize: Theme.typography.sizes.small
        }
    }

    // The hatch's edge: it is a compartment of its own, not one more
    // instrument.
    Rectangle {
        id: divider
        anchors.left: row.right
        anchors.leftMargin: Theme.metrics.space.md
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Theme.typography.sizes.icon + Theme.metrics.space.sm
        color: Theme.colors.accent.primary
        opacity: 0.45
    }
}
