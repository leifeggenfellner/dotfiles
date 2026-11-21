import QtQuick
import "../core"

// ── PageHeader ────────────────────────────────────────────────
// Back arrow, title and, with `hasSwitch`, the subject's main switch.

Item {
    id: root

    property string title: ""
    property bool hasSwitch: false
    property bool checked: false
    property bool busy: false

    signal back
    signal toggled

    implicitHeight: 32

    Rectangle {
        id: backButton
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: Theme.metrics.radius.small
        color: backMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"

        Icon {
            anchors.centerIn: parent
            name: "chevron-left"
            size: Theme.typography.sizes.body + 1
            color: backMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
        }
        MouseArea {
            id: backMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.back()
        }
    }

    Text {
        anchors.left: backButton.right
        anchors.leftMargin: Theme.metrics.space.sm
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: Theme.colors.fg.primary
        font.family: Theme.typography.families.display
        font.pointSize: Theme.typography.sizes.body + 2
    }

    Spinner {
        visible: root.busy
        anchors.right: toggle.left
        anchors.rightMargin: Theme.metrics.space.sm
        anchors.verticalCenter: parent.verticalCenter
        size: Theme.typography.sizes.body
    }

    Toggle {
        id: toggle
        visible: root.hasSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        onToggled: root.toggled()
    }
}
