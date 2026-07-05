import QtQuick
import "../../core"
import "../../components"

// ── PowerMenuPopout ───────────────────────────────────────────
// Session actions (legacy power menu parity). Services: session.

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var session: services.session ?? null

    width: 220
    spacing: Theme.metrics.space.xs

    Repeater {
        model: [
            { label: "Lock", icon: "lock", action: "lock" },
            { label: "Logout", icon: "logout", action: "logout" },
            { label: "Reboot", icon: "reboot", action: "reboot" },
            { label: "Shutdown", icon: "power", action: "poweroff" }
        ]

        Rectangle {
            id: row

            required property var modelData

            width: parent.width
            height: 36
            radius: Theme.metrics.radius.small
            color: rowMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Theme.metrics.space.sm
                spacing: Theme.metrics.space.md

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    name: row.modelData.icon
                    size: Theme.typography.sizes.body + 2
                    color: rowMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.modelData.label
                    color: Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    ShellState.closePopout();
                    if (root.session)
                        root.session[row.modelData.action]();
                }
            }
        }
    }
}
