import QtQuick
import "../../core"
import "../../components"

// ── SessionLockTile ──────────────────────────────────────────
// Dashboard-region tile that engages the canonical lock path.
// Content-only: DashboardGrid wraps this in DashboardCard chrome
// (title/subtitle/hover/focus ring). The tile does not know how
// locking works — it just fires services.session.lock(), which
// runs `lock-screen`, which routes veil-then-lock via IPC when
// the rice shell is up (phase 6). Every lock trigger converges
// on the same script.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var session: services.session ?? null
    readonly property string label: settings.label ?? "Lock"
    readonly property string hint: settings.hint ?? "Engage the lockscreen"
    readonly property string iconName: settings.icon ?? "lock"
    readonly property real iconScale: 1.0 + (settings.iconScale ?? 0.0)

    // Consumed by DashboardGrid keyboard nav (Enter/Space).
    function primaryAction() {
        root.activate();
    }

    function activate() {
        if (root.session)
            root.session.lock();
    }

    implicitHeight: layout.implicitHeight + Theme.metrics.space.md * 2

    MouseArea {
        id: clickArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: root.activate()
    }

    Column {
        id: layout

        anchors.centerIn: parent
        width: parent.width
        spacing: Theme.metrics.space.sm

        Item {
            width: parent.width
            height: iconWrap.implicitHeight

            Item {
                id: iconWrap
                anchors.horizontalCenter: parent.horizontalCenter
                implicitWidth: Theme.typography.sizes.icon * 2.4
                implicitHeight: Theme.typography.sizes.icon * 2.4

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.implicitWidth
                    height: parent.implicitHeight
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: clickArea.containsMouse ? Theme.colors.accent.primary : Theme.colors.bg.surface1
                    opacity: clickArea.containsMouse ? 0.9 : 0.55
                    scale: clickArea.pressed ? 0.96 : (clickArea.containsMouse ? 1.04 : 1.0)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                    Behavior on scale {
                        MotionAnim {
                            spec: clickArea.pressed ? Motion.sealPress : Motion.stateChange
                        }
                    }
                }

                Icon {
                    anchors.centerIn: parent
                    name: root.iconName
                    size: Theme.typography.sizes.icon * root.iconScale
                    color: clickArea.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: root.label
            horizontalAlignment: Text.AlignHCenter
            color: Theme.colors.fg.primary
            elide: Text.ElideRight
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.heading - 2
            font.letterSpacing: 1
        }

        Text {
            width: parent.width
            text: root.hint
            horizontalAlignment: Text.AlignHCenter
            color: Theme.colors.fg.subtle
            wrapMode: Text.WordWrap
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }
}
