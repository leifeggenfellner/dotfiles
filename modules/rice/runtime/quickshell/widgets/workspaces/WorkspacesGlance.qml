import QtQuick
import "../../core"

// ── WorkspacesGlance ──────────────────────────────────────────
// Workspace indicator. Identity comes entirely from theme settings:
//   settings.items = [ { id, label, icon, color } ]
// icon follows the D-016 heuristic: a value containing "/" is an
// assetUrl spec (image file / raster output); anything else is a
// font glyph tinted with the item's color. With empty settings it
// degrades to a plain numeric readout. Services: hypr (injected).

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var items: settings.items ?? []
    readonly property int active: services.hypr ? services.hypr.activeWorkspace : 1

    implicitWidth: items.length > 0 ? row.width : fallback.width
    implicitHeight: Theme.metrics.bar.height

    Row {
        id: row
        visible: root.items.length > 0
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.metrics.space.sm

        Repeater {
            model: root.items

            Item {
                id: slot

                required property var modelData
                readonly property bool isActive: modelData.id === root.active
                readonly property color wsColor: modelData.color ?? Theme.colors.accent.primary
                readonly property string iconSpec: modelData.icon ?? ""
                readonly property bool iconIsImage: Theme.iconIsFile(iconSpec)

                width: 30
                height: 30

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 4
                    height: parent.height + 4
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: slot.wsColor
                    opacity: slot.isActive ? 0.9 : 0

                    Behavior on opacity {
                        MotionAnim {}
                    }
                }

                // Authored color artwork (theme-provided); the widget only
                // dims inactive entries and rings the active one.
                Image {
                    visible: slot.iconIsImage
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: slot.iconIsImage ? Theme.assetUrl(slot.iconSpec) : ""
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    opacity: slot.isActive ? 1 : 0.45

                    Behavior on opacity {
                        MotionAnim {}
                    }
                }

                // Glyph identity, tinted with the item's color.
                Text {
                    visible: !slot.iconIsImage
                    anchors.centerIn: parent
                    text: slot.iconIsImage ? "" : slot.iconSpec
                    color: slot.wsColor
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.icon
                    opacity: slot.isActive ? 1 : 0.45

                    Behavior on opacity {
                        MotionAnim {}
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.services.hypr?.switchWorkspace(slot.modelData.id)
                }
            }
        }
    }

    Text {
        id: fallback
        visible: root.items.length === 0
        anchors.verticalCenter: parent.verticalCenter
        text: "ws " + root.active
        color: Theme.colors.fg.muted
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.bar
    }
}
