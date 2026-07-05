import QtQuick
import "../../core"

// ── WorkspacesGlance ──────────────────────────────────────────
// Workspace indicator. Identity comes entirely from theme settings:
//   settings.items = [ { id, label, icon (assetUrl spec), color } ]
// With empty settings it degrades to a plain numeric readout.
// Services: hypr (injected).

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
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    source: Theme.assetUrl(slot.modelData.icon ?? "")
                    sourceSize.width: 48
                    sourceSize.height: 48
                    fillMode: Image.PreserveAspectFit
                    smooth: true
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
