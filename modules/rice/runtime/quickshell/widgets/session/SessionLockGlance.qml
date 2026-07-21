import QtQuick
import "../../core"
import "../../components"
import "../../services/session"

// ── SessionLockGlance ────────────────────────────────────────
// Bar-region lock affordance. No popout — one-click lock via the
// canonical SessionState.lock() path (which routes through
// `lock-screen` → ambient.lockWithVeil → rice-lock-screen).
//
// Descriptor: `region: "right"`, `services: ["session"]`, no popout.
// TopBar's outer MouseArea is disabled when popout === null, so the
// glance's own MouseArea receives clicks directly.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var session: services.session ?? SessionState
    readonly property string iconName: settings.icon ?? "lock"
    readonly property string tooltip: settings.tooltip ?? "Lock"

    implicitWidth: icon.implicitWidth
    implicitHeight: Theme.metrics.bar.height

    MouseArea {
        id: hitArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.session)
                root.session.lock();
        }
    }

    Icon {
        id: icon
        anchors.centerIn: parent
        name: root.iconName
        color: hitArea.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
        scale: hitArea.pressed ? 0.92 : (hitArea.containsMouse ? 1.08 : 1.0)

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }
        Behavior on scale {
            MotionAnim {
                spec: hitArea.pressed ? Motion.sealPress : Motion.stateChange
            }
        }
    }
}
