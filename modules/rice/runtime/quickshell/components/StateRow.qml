import QtQuick
import "../core"

// ── StateRow ──────────────────────────────────────────────────
// One thing in a list, in one of four states the service reports:
// idle, `pending` (spinner, locked), `active` (accent) and failed
// (`failure` text under the row). Children go to the trailing slot
// (signal bars, badges). `actions` [{ id, label, danger? }] sit
// behind ⋯ and come back through `action(id)`.
// Keys: Enter or Space clicks, → or the menu key opens the actions.

FocusScope {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool pending: false
    property string failure: ""
    property var actions: []
    property bool expanded: false
    default property alias trailing: trailingRow.data

    signal clicked
    signal action(string id)

    implicitHeight: column.implicitHeight
    activeFocusOnTab: true

    onActiveFocusChanged: if (!activeFocus)
        expanded = false

    Column {
        id: column
        width: parent.width
        spacing: 2

        Rectangle {
            id: face
            // The row's own focus; the scope returns here from the actions.
            focus: true
            width: parent.width
            height: root.subtitle.length > 0 ? 44 : 36
            radius: Theme.metrics.radius.small
            color: root.active ? Qt.alpha(Theme.colors.accent.primary, 0.14) : (mouse.containsMouse ? Theme.colors.bg.elevated : "transparent")
            border.width: root.activeFocus && !actionsRow.activeFocus ? 2 : 0
            border.color: Theme.colors.fg.primary

            Icon {
                id: glyph
                visible: root.icon.length > 0 && !root.pending
                x: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon.length > 0 ? root.icon : "unknown"
                size: Theme.typography.sizes.body + 2
                color: root.active ? Theme.colors.accent.primary : Theme.colors.fg.muted
            }
            Spinner {
                id: spin
                visible: root.pending
                x: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                size: Theme.typography.sizes.body
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: root.icon.length > 0 || root.pending ? Theme.metrics.space.sm * 2 + Theme.typography.sizes.body + 4 : Theme.metrics.space.sm
                anchors.right: trailingRow.left
                anchors.rightMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    width: parent.width
                    text: root.title
                    elide: Text.ElideRight
                    color: root.active ? Theme.colors.accent.primary : Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                }
                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: root.subtitle
                    elide: Text.ElideRight
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !root.pending
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    face.forceActiveFocus();
                    if (event.button === Qt.RightButton && root.actions.length > 0)
                        root.expanded = !root.expanded;
                    else
                        root.clicked();
                }
            }

            Row {
                id: trailingRow
                anchors.right: moreButton.left
                anchors.rightMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.metrics.space.sm
            }

            Item {
                id: moreButton
                anchors.right: parent.right
                width: root.actions.length > 0 ? 28 : Theme.metrics.space.xs
                height: parent.height

                Icon {
                    visible: root.actions.length > 0
                    anchors.centerIn: parent
                    name: "more"
                    size: Theme.typography.sizes.body
                    color: moreMouse.containsMouse || root.expanded ? Theme.colors.accent.primary : Theme.colors.fg.subtle
                }
                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    enabled: root.actions.length > 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded ? root.collapse() : root.openActions()
                }
            }
        }

        // The actions, inline under the row: a menu that cannot be
        // clipped by the popout and needs no window of its own.
        FocusScope {
            id: actionsRow
            visible: root.expanded && root.actions.length > 0
            x: Theme.metrics.space.sm * 2 + Theme.typography.sizes.body + 4
            width: chips.implicitWidth
            height: visible ? chips.implicitHeight : 0

            Row {
                id: chips
                spacing: Theme.metrics.space.xs

                Repeater {
                    model: root.actions
                    Rectangle {
                        id: chip
                        required property var modelData
                        required property int index
                        width: chipLabel.implicitWidth + Theme.metrics.space.md * 2
                        height: 24
                        radius: height / 2
                        activeFocusOnTab: true
                        color: chipMouse.containsMouse || activeFocus ? Theme.colors.bg.elevated : Theme.colors.bg.sunken
                        border.width: 1
                        border.color: activeFocus ? Theme.colors.fg.primary : (modelData.danger ? Qt.alpha(Theme.colors.state.danger, 0.6) : Theme.colors.bg.surface1)

                        function fire() {
                            root.collapse();
                            root.action(modelData.id);
                        }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: chip.modelData.label
                            color: chip.modelData.danger ? Theme.colors.state.danger : Theme.colors.fg.primary
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                        }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: chip.fire()
                        }
                        Keys.onReturnPressed: chip.fire()
                        Keys.onEnterPressed: chip.fire()
                        Keys.onSpacePressed: chip.fire()
                        Keys.onEscapePressed: root.collapse()
                        Keys.onLeftPressed: event => {
                            if (index === 0) {
                                root.collapse();
                            } else {
                                event.accepted = false;
                            }
                        }
                    }
                }
            }
        }

        Text {
            visible: root.failure.length > 0
            x: Theme.metrics.space.sm * 2 + Theme.typography.sizes.body + 4
            width: parent.width - x - Theme.metrics.space.sm
            text: root.failure
            wrapMode: Text.WordWrap
            color: Theme.colors.state.danger
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }

    function collapse() {
        face.forceActiveFocus();
        root.expanded = false;
    }

    function openActions() {
        if (root.actions.length === 0)
            return false;
        root.expanded = true;
        Qt.callLater(() => chips.children.find(c => c.activeFocusOnTab)?.forceActiveFocus());
        return true;
    }

    Keys.onReturnPressed: if (!root.pending)
        root.clicked()
    Keys.onEnterPressed: if (!root.pending)
        root.clicked()
    Keys.onSpacePressed: if (!root.pending)
        root.clicked()
    Keys.onRightPressed: event => event.accepted = root.openActions()
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu)
            event.accepted = root.openActions();
    }
    Keys.onEscapePressed: event => {
        if (root.expanded)
            root.expanded = false;
        else
            event.accepted = false;
    }
}
