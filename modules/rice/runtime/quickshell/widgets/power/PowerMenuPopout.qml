import QtQuick
import "../../core"
import "../../components"

// ── PowerMenuPopout ───────────────────────────────────────────
// Session actions (legacy power menu parity). Services: session.
// settings.delegate = "radial" opts into the tier-3 delegate slot;
// default list behavior remains unchanged for unconfigured themes.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var session: services.session ?? null
    readonly property string delegateName: settings.delegate ?? "list"
    readonly property bool radial: delegateName === "radial"
    readonly property string centerLabel: settings.centerLabel ?? "Power"
    readonly property var labelOverrides: settings.labels ?? ({})
    readonly property var baseActions: [
        {
            label: "Lock",
            icon: "lock",
            action: "lock"
        },
        {
            label: "Logout",
            icon: "logout",
            action: "logout"
        },
        {
            label: "Reboot",
            icon: "reboot",
            action: "reboot"
        },
        {
            label: "Shutdown",
            icon: "power",
            action: "poweroff"
        }
    ]
    readonly property var actions: baseActions.map(a => ({
                label: labelOverrides[a.action] ?? a.label,
                icon: a.icon,
                action: a.action
            }))

    implicitWidth: radial ? 272 : 220
    implicitHeight: radial ? 272 : root.actions.length * 36 + Math.max(0, root.actions.length - 1) * Theme.metrics.space.xs

    function trigger(action) {
        ShellState.closePopout();
        if (root.session)
            root.session[action]();
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.radial ? radialDelegate : listDelegate
    }

    Component {
        id: listDelegate

        Column {
            width: 220
            spacing: Theme.metrics.space.xs

            Repeater {
                model: root.actions

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
                        onClicked: root.trigger(row.modelData.action)
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                }
            }
        }
    }

    Component {
        id: radialDelegate

        Item {
            id: ring

            width: 272
            height: 272

            Rectangle {
                anchors.centerIn: parent
                width: 112
                height: 112
                radius: width / 2
                color: Theme.colors.bg.sunken
                border.width: 1
                border.color: Theme.colors.accent.primary

                Text {
                    anchors.centerIn: parent
                    width: parent.width - Theme.metrics.space.md * 2
                    text: root.centerLabel
                    color: Theme.colors.fg.primary
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.body
                }
            }

            Repeater {
                model: root.actions

                Rectangle {
                    id: sigil

                    required property var modelData
                    required property int index

                    readonly property real angle: -Math.PI / 2 + index * (Math.PI * 2 / Math.max(1, root.actions.length))

                    width: 82
                    height: 82
                    radius: width / 2
                    x: ring.width / 2 - width / 2 + Math.cos(angle) * 94
                    y: ring.height / 2 - height / 2 + Math.sin(angle) * 94
                    scale: sigilMouse.pressed ? 0.92 : (sigilMouse.containsMouse ? 1.06 : 1)
                    color: sigilMouse.containsMouse ? Theme.colors.bg.elevated : Theme.colors.bg.base
                    border.width: 1
                    border.color: sigilMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.bg.surface1

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - Theme.metrics.space.sm * 2
                        spacing: Theme.metrics.space.xs

                        Icon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            name: sigil.modelData.icon
                            size: Theme.typography.sizes.icon + 4
                            color: sigilMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
                        }
                        Text {
                            width: parent.width
                            text: sigil.modelData.label
                            color: Theme.colors.fg.primary
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                        }
                    }

                    MouseArea {
                        id: sigilMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.trigger(sigil.modelData.action)
                    }

                    Behavior on x {
                        MotionAnim {
                            spec: Motion.ritualAssemble
                        }
                    }
                    Behavior on y {
                        MotionAnim {
                            spec: Motion.ritualAssemble
                        }
                    }
                    Behavior on scale {
                        MotionAnim {
                            spec: sigilMouse.pressed ? Motion.sealPress : Motion.stateChange
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                }
            }
        }
    }
}
