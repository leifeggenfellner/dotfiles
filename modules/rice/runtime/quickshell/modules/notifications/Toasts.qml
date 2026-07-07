import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/notifications"

// ── Toasts ────────────────────────────────────────────────────
// Transient popup stack for incoming notifications (top-right).
// Subscribes to NotificationState.received — the user-initiated
// hint — so it never fires from boot-time state. Cards auto-expire
// after a few seconds; clicking dismisses the notification.

PanelWindow {
    id: toasts

    required property var modelData
    screen: modelData

    visible: toastModel.count > 0

    WlrLayershell.namespace: "rice-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        right: Theme.metrics.bar.margin
    }

    implicitWidth: 340
    implicitHeight: stack.height
    color: "transparent"

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationState
        function onReceived(entry) {
            if (ShellState.doNotDisturb)
                return;
            toastModel.append({
                nid: entry.id,
                app: entry.app,
                summary: entry.summary,
                body: entry.body,
                urgency: entry.urgency
            });
            Sound.play(entry.urgency === 2 ? "notification-critical" : "notification");
            // Keep the stack shallow; oldest toast yields first.
            if (toastModel.count > 4)
                toastModel.remove(0);
        }
    }

    function removeToast(nid) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).nid === nid) {
                toastModel.remove(i);
                return;
            }
        }
    }

    Column {
        id: stack
        width: parent.width
        spacing: Theme.metrics.space.sm

        Repeater {
            model: toastModel

            Rectangle {
                id: card

                required property var model

                width: stack.width
                height: content.height + Theme.metrics.space.md * 2
                radius: Theme.metrics.radius.medium
                color: card.model.urgency === 2 ? Theme.colors.bg.elevated : Theme.colors.bg.mantle
                border.width: 1
                border.color: card.model.urgency === 2 ? Theme.colors.state.danger : Theme.colors.bg.surface1

                opacity: 0
                Component.onCompleted: opacity = 0.97

                Behavior on opacity {
                    MotionAnim {
                        spec: Motion.panelOpen
                    }
                }

                Timer {
                    interval: card.model.urgency === 2 ? 8000 : 5000
                    running: true
                    onTriggered: toasts.removeToast(card.model.nid)
                }

                Rectangle {
                    width: 4
                    height: parent.height - Theme.metrics.space.md
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: card.model.urgency === 2 ? Theme.colors.state.danger
                        : (card.model.urgency === 0 ? Theme.colors.fg.subtle : Theme.colors.accent.primary)
                }

                Column {
                    id: content
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Theme.metrics.space.lg
                    anchors.rightMargin: Theme.metrics.space.md
                    spacing: 2

                    Text {
                        text: card.model.app
                        color: card.model.urgency === 2 ? Theme.colors.state.danger : Theme.colors.accent.primary
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.small
                    }
                    Text {
                        width: parent.width
                        text: card.model.summary
                        color: Theme.colors.fg.primary
                        elide: Text.ElideRight
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.body
                        font.weight: Theme.typography.weights.medium
                    }
                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: card.model.body
                        color: Theme.colors.fg.muted
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.small
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        NotificationState.dismiss(card.model.nid);
                        toasts.removeToast(card.model.nid);
                    }
                }
            }
        }
    }
}
