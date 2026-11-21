import QtQuick
import "../core"

// ── ToggleTile ────────────────────────────────────────────────
// A quick setting: icon, label and a live state line. The body
// toggles; with `hasPage`, the chevron strip opens the subject's
// page. Keys: Space toggles, Enter or → opens (else toggles).

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string detail: ""
    property bool checked: false
    property bool busy: false
    property bool hasPage: false
    property bool available: true

    signal toggled
    signal opened

    implicitHeight: 56
    radius: Theme.metrics.radius.medium
    color: checked ? Qt.alpha(Theme.colors.accent.primary, 0.18) : (body.containsMouse ? Theme.colors.bg.elevated : Theme.colors.bg.sunken)
    border.width: activeFocus ? 2 : 1
    border.color: activeFocus ? Theme.colors.fg.primary : (checked ? Qt.alpha(Theme.colors.accent.primary, 0.6) : Theme.colors.bg.surface1)
    opacity: available ? 1 : 0.45
    activeFocusOnTab: available

    Behavior on color {
        ColorAnimation {
            duration: Motion.stateChange.duration
        }
    }

    Item {
        id: face
        anchors.fill: parent
        anchors.rightMargin: root.hasPage ? 28 : 0

        Icon {
            id: glyph
            x: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            name: root.icon
            size: Theme.typography.sizes.icon
            color: root.checked ? Theme.colors.accent.primary : Theme.colors.fg.subtle
            visible: !root.busy
        }
        Spinner {
            anchors.centerIn: glyph
            size: Theme.typography.sizes.icon - 2
            visible: root.busy
        }

        Column {
            anchors.left: glyph.right
            anchors.leftMargin: Theme.metrics.space.sm
            anchors.right: parent.right
            anchors.rightMargin: Theme.metrics.space.xs
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: root.label
                elide: Text.ElideRight
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body - 1
                font.weight: Font.Medium
            }
            Text {
                width: parent.width
                visible: text.length > 0
                text: root.detail
                elide: Text.ElideRight
                color: root.checked ? Theme.colors.accent.primary : Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
            }
        }

        MouseArea {
            id: body
            anchors.fill: parent
            hoverEnabled: true
            enabled: root.available
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()
        }
    }

    Rectangle {
        visible: root.hasPage
        anchors.right: parent.right
        width: 28
        height: parent.height
        radius: root.radius
        color: more.containsMouse ? Theme.colors.bg.elevated : "transparent"

        Rectangle {
            width: 1
            height: parent.height - Theme.metrics.space.md * 2
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.colors.bg.surface1
        }
        Icon {
            anchors.centerIn: parent
            name: "chevron-right"
            size: Theme.typography.sizes.body
            color: more.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle
        }
        MouseArea {
            id: more
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened()
        }
    }

    Keys.onSpacePressed: root.toggled()
    Keys.onReturnPressed: root.hasPage ? root.opened() : root.toggled()
    Keys.onEnterPressed: root.hasPage ? root.opened() : root.toggled()
    Keys.onRightPressed: event => {
        if (root.hasPage)
            root.opened();
        else
            event.accepted = false;
    }
}
