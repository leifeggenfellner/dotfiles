import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/notifications"
import "../../services/prefs"

// ── NotificationCenter ───────────────────────────────────────
// Correspondence panel: tracked freedesktop notifications with
// urgency styling, action buttons, inline reply, and DND control.

PanelWindow {
    id: center

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.notificationsOpen
    readonly property var settings: Theme.widgetConfig("correspondence").settings ?? ({})
    readonly property string title: settings.title ?? "Correspondence"
    readonly property string clearLabel: settings.clearLabel ?? "clear"
    readonly property string quietLabel: settings.quietLabel ?? "quiet"
    readonly property string audibleLabel: settings.audibleLabel ?? "audible"
    readonly property string emptyLabel: settings.emptyLabel ?? "All quiet."
    readonly property string dndEmptyLabel: settings.dndEmptyLabel ?? "The room is quiet."

    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        right: Theme.metrics.bar.margin
        bottom: Theme.metrics.bar.margin
    }

    implicitWidth: 380
    color: "transparent"

    function urgencyColor(urgency) {
        if (urgency === 2)
            return Theme.colors.state.danger;
        if (urgency === 0)
            return Theme.colors.fg.subtle;
        return Theme.colors.accent.primary;
    }

    function urgencyText(urgency) {
        if (urgency === 2)
            return "urgent";
        if (urgency === 0)
            return "low";
        return "sealed";
    }

    Rectangle {
        id: panel

        width: parent.width
        height: parent.height
        radius: Theme.metrics.radius.large
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: ShellState.doNotDisturb ? Theme.colors.state.warn : Theme.colors.bg.surface1

        x: center.open ? 0 : Theme.metrics.space.lg * 2
        opacity: center.open ? 0.96 : 0

        Behavior on x {
            MotionAnim {
                spec: center.open ? Motion.panelOpen : Motion.panelClose
            }
        }
        Behavior on opacity {
            MotionAnim {
                spec: center.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: center.open
            Keys.onEscapePressed: ShellState.toggleNotifications()

            Column {
                anchors.fill: parent
                anchors.margins: Theme.metrics.space.lg
                spacing: Theme.metrics.space.md

                Item {
                    width: parent.width
                    height: Math.max(headerTitle.height + headerCount.height, dndButton.height)

                    Column {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Text {
                            id: headerTitle
                            text: center.title
                            color: Theme.colors.fg.primary
                            font.family: Theme.typography.families.display
                            font.pointSize: Theme.typography.sizes.heading
                        }
                        Text {
                            id: headerCount
                            text: NotificationState.notifications.length + " sealed"
                            color: Theme.colors.fg.subtle
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.metrics.space.sm

                        Rectangle {
                            id: dndButton
                            width: dndText.width + Theme.metrics.space.md * 2
                            height: 28
                            radius: Theme.metrics.radius.small
                            color: dndMouse.containsMouse ? Theme.colors.bg.elevated : Theme.colors.bg.sunken
                            border.width: 1
                            border.color: ShellState.doNotDisturb ? Theme.colors.state.warn : Theme.colors.bg.surface1

                            Text {
                                id: dndText
                                anchors.centerIn: parent
                                text: ShellState.doNotDisturb ? center.quietLabel : center.audibleLabel
                                color: ShellState.doNotDisturb ? Theme.colors.state.warn : Theme.colors.fg.muted
                                font.family: Theme.typography.families.sans
                                font.pointSize: Theme.typography.sizes.small
                            }

                            MouseArea {
                                id: dndMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: PrefsState.setDoNotDisturb(!PrefsState.doNotDisturb)
                            }
                        }

                        Text {
                            visible: NotificationState.notifications.length > 0
                            text: center.clearLabel
                            color: clearMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                anchors.margins: -Theme.metrics.space.sm
                                hoverEnabled: true
                                onClicked: NotificationState.clearAll()
                            }
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: parent.height - y
                    contentWidth: width
                    contentHeight: stack.height
                    clip: true

                    Column {
                        id: stack
                        width: parent.width
                        spacing: Theme.metrics.space.sm

                        Repeater {
                            model: NotificationState.notifications

                            Rectangle {
                                id: card

                                required property var modelData

                                width: stack.width
                                height: cardContent.height + Theme.metrics.space.md * 2
                                radius: Theme.metrics.radius.medium
                                color: modelData.urgency === 2 ? Theme.colors.bg.elevated : Theme.colors.bg.sunken
                                border.width: 1
                                border.color: center.urgencyColor(modelData.urgency)

                                Rectangle {
                                    width: 4
                                    height: parent.height - Theme.metrics.space.md
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.metrics.space.sm
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 2
                                    color: center.urgencyColor(card.modelData.urgency)
                                }

                                Column {
                                    id: cardContent
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: Theme.metrics.space.lg
                                    anchors.rightMargin: Theme.metrics.space.md
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.metrics.space.xs

                                    Row {
                                        width: parent.width
                                        spacing: Theme.metrics.space.sm

                                        Text {
                                            width: parent.width - statusText.width - Theme.metrics.space.sm
                                            text: card.modelData.app + " / " + card.modelData.time
                                            color: Theme.colors.fg.subtle
                                            elide: Text.ElideRight
                                            font.family: Theme.typography.families.mono
                                            font.pointSize: Theme.typography.sizes.small
                                        }
                                        Text {
                                            id: statusText
                                            text: center.urgencyText(card.modelData.urgency)
                                            color: center.urgencyColor(card.modelData.urgency)
                                            font.family: Theme.typography.families.sans
                                            font.pointSize: Theme.typography.sizes.small
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: card.modelData.summary
                                        color: Theme.colors.fg.primary
                                        elide: Text.ElideRight
                                        font.family: Theme.typography.families.sans
                                        font.pointSize: Theme.typography.sizes.body
                                        font.weight: Theme.typography.weights.medium
                                    }

                                    Text {
                                        width: parent.width
                                        visible: text.length > 0
                                        text: card.modelData.body
                                        color: Theme.colors.fg.muted
                                        textFormat: Text.PlainText
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 4
                                        font.family: Theme.typography.families.sans
                                        font.pointSize: Theme.typography.sizes.small
                                    }

                                    Row {
                                        visible: card.modelData.actions.length > 0
                                        width: parent.width
                                        spacing: Theme.metrics.space.sm

                                        Repeater {
                                            model: card.modelData.actions

                                            Rectangle {
                                                id: actionButton

                                                required property var modelData

                                                width: Math.min(actionText.implicitWidth + Theme.metrics.space.md * 2, 132)
                                                height: 28
                                                radius: Theme.metrics.radius.small
                                                color: actionMouse.containsMouse ? Theme.colors.bg.elevated : Theme.colors.bg.mantle
                                                border.width: 1
                                                border.color: Theme.colors.bg.surface1

                                                Text {
                                                    id: actionText
                                                    anchors.centerIn: parent
                                                    width: parent.width - Theme.metrics.space.sm
                                                    text: actionButton.modelData.text
                                                    color: Theme.colors.accent.primary
                                                    elide: Text.ElideRight
                                                    horizontalAlignment: Text.AlignHCenter
                                                    font.family: Theme.typography.families.sans
                                                    font.pointSize: Theme.typography.sizes.small
                                                }

                                                MouseArea {
                                                    id: actionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    onClicked: NotificationState.invokeAction(card.modelData.id, actionButton.modelData.identifier)
                                                }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: card.modelData.hasInlineReply
                                        width: parent.width
                                        height: 32
                                        radius: Theme.metrics.radius.small
                                        color: Theme.colors.bg.mantle
                                        border.width: 1
                                        border.color: replyInput.activeFocus ? Theme.colors.accent.primary : Theme.colors.bg.surface1

                                        TextInput {
                                            id: replyInput
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.metrics.space.sm
                                            anchors.rightMargin: Theme.metrics.space.sm
                                            verticalAlignment: TextInput.AlignVCenter
                                            color: Theme.colors.fg.primary
                                            selectionColor: Theme.colors.accent.primary
                                            selectedTextColor: Theme.colors.bg.base
                                            font.family: Theme.typography.families.sans
                                            font.pointSize: Theme.typography.sizes.body
                                            clip: true
                                            onAccepted: {
                                                NotificationState.sendInlineReply(card.modelData.id, text);
                                                text = "";
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: replyInput.text.length === 0 && !replyInput.activeFocus
                                                text: card.modelData.replyPlaceholder
                                                color: Theme.colors.fg.subtle
                                                font.family: Theme.typography.families.sans
                                                font.pointSize: Theme.typography.sizes.small
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        text: "dismiss"
                                        color: dismissMouse.containsMouse ? Theme.colors.state.warn : Theme.colors.fg.subtle
                                        font.family: Theme.typography.families.sans
                                        font.pointSize: Theme.typography.sizes.small

                                        MouseArea {
                                            id: dismissMouse
                                            anchors.fill: parent
                                            anchors.margins: -Theme.metrics.space.sm
                                            hoverEnabled: true
                                            onClicked: NotificationState.dismiss(card.modelData.id)
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: NotificationState.notifications.length === 0
                            width: parent.width
                            text: ShellState.doNotDisturb ? center.dndEmptyLabel : center.emptyLabel
                            color: Theme.colors.fg.subtle
                            horizontalAlignment: Text.AlignHCenter
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.body
                        }
                    }
                }
            }
        }
    }
}
