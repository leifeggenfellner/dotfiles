import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/notifications"

// ── Toasts ────────────────────────────────────────────────────
// Transient popup stack for incoming notifications (top-right).
// Subscribes to NotificationState.received — the user-initiated
// hint — so it never fires from boot-time state. Cards auto-expire
// after a few seconds; clicking dismisses the notification.
//
// Personas (D-056): correspondence settings may map apps to a
// persona — a card variant, icon, sound and a label shown beside
// the real app name. Unmapped apps keep the plain card; urgency
// still wins the colours and the critical sound.

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

    readonly property var personas: (Theme.widgetConfig("correspondence").settings ?? ({})).personas ?? []

    // Matched case-insensitively on the app name or desktop entry.
    function personaFor(entry) {
        const keys = [entry.app, entry.desktopEntry].filter(k => k && k.length > 0).map(k => k.toLowerCase());
        return personas.find(p => (p.apps ?? []).some(a => keys.includes(a.toLowerCase()))) ?? null;
    }

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationState
        function onReceived(entry) {
            if (ShellState.doNotDisturb)
                return;
            const persona = toasts.personaFor(entry);
            toastModel.append({
                nid: entry.id,
                app: entry.app,
                summary: entry.summary,
                body: entry.body,
                urgency: entry.urgency,
                variant: persona ? (persona.variant ?? "letter") : "",
                personaLabel: persona?.label ?? "",
                personaIcon: persona?.icon ?? "mail"
            });
            if (entry.urgency === 2 || !persona?.sound || !Sound.play(persona.sound))
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
                readonly property bool letter: card.model.variant === "letter"

                width: stack.width
                height: content.height + Theme.metrics.space.md * 2
                radius: Theme.metrics.radius.medium
                color: card.model.urgency === 2 || card.letter ? Theme.colors.bg.elevated : Theme.colors.bg.mantle
                border.width: 1
                border.color: card.model.urgency === 2 ? Theme.colors.state.danger
                    : (card.letter ? Qt.rgba(Theme.colors.accent.primary.r, Theme.colors.accent.primary.g, Theme.colors.accent.primary.b, 0.55) : Theme.colors.bg.surface1)

                opacity: 0
                // A letter is delivered: it slides in from the screen
                // edge. Motion specs collapse to 0ms under reduce-motion.
                transform: Translate {
                    id: arrival
                    x: card.letter ? Theme.metrics.space.lg * 2 : 0
                    Behavior on x {
                        MotionAnim {
                            spec: Motion.panelOpen
                        }
                    }
                }
                Component.onCompleted: {
                    opacity = 0.97;
                    arrival.x = 0;
                }

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
                    visible: !card.letter
                    width: 4
                    height: parent.height - Theme.metrics.space.md
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 2
                    color: card.model.urgency === 2 ? Theme.colors.state.danger
                        : (card.model.urgency === 0 ? Theme.colors.fg.subtle : Theme.colors.accent.primary)
                }

                // The letter's seal: the persona's icon on a pressed disc.
                Rectangle {
                    id: seal
                    visible: card.letter
                    width: Theme.typography.sizes.icon * 2
                    height: width
                    radius: width / 2
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.md
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.colors.bg.sunken
                    border.width: 1
                    border.color: card.model.urgency === 2 ? Theme.colors.state.danger : Theme.colors.accent.primary

                    scale: 1.15
                    Component.onCompleted: scale = 1
                    Behavior on scale {
                        MotionAnim {
                            spec: Motion.sealPress
                        }
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: card.model.personaIcon
                        size: Theme.typography.sizes.icon
                        color: Theme.colors.accent.primary
                    }
                }

                Column {
                    id: content
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: card.letter ? seal.right : parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: card.letter ? Theme.metrics.space.md : Theme.metrics.space.lg
                    anchors.rightMargin: Theme.metrics.space.md
                    spacing: 2

                    Row {
                        width: parent.width
                        spacing: Theme.metrics.space.xs

                        Text {
                            id: appName
                            text: card.model.app
                            color: card.model.urgency === 2 ? Theme.colors.state.danger : Theme.colors.accent.primary
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                        }
                        Text {
                            visible: card.model.personaLabel.length > 0
                            width: Math.max(0, parent.width - appName.width - parent.spacing)
                            text: "· " + card.model.personaLabel
                            color: Theme.colors.fg.subtle
                            elide: Text.ElideRight
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                            font.italic: true
                        }
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
