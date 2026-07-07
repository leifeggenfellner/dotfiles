pragma Singleton
import QtQuick
import Quickshell.Services.Notifications

// ── NotificationState — REAL ──────────────────────────────────
// Quickshell's freedesktop notification server (D-008 tier 1).
// NOTE: only one daemon may own org.freedesktop.Notifications —
// while swaync runs, it keeps the name and nothing arrives here.
// Permanent handoff happens with shell autostart (ROADMAP Phase 7).
// Registration failure is not detectable from QML, so `available`
// stays true; the debug overlay shows the pending count regardless.
//
//   state:    available, busy, error, mock,
//             notifications[] {id, app, summary, body, urgency, time,
//                              actions[], hasInlineReply, replyPlaceholder}
//   commands: dismiss(id), clearAll(), invokeAction(id, actionId),
//             sendInlineReply(id, text)
//   signals:  received(id) — user-initiated hint for toast surfaces

Item {
    id: notifs

    readonly property bool mock: false
    readonly property bool available: true
    readonly property bool busy: false
    readonly property string error: ""

    // Carries the full entry: tracked-model insertion is async, so
    // consumers must not need to look the notification up on arrival.
    signal received(var entry)

    property var _times: ({})
    property int _timesBump: 0

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyImagesSupported: true
        imageSupported: true
        actionsSupported: true
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true;
            notifs._times[n.id] = Qt.formatTime(new Date(), "HH:mm");
            notifs._timesBump++;
            notifs.received(notifs._wrap(n));
        }
    }

    // Same wrapper shape the mock had, newest first — consumers
    // were built against it and need no changes.
    readonly property var notifications: {
        void notifs._timesBump;
        return server.trackedNotifications.values.map(n => notifs._wrap(n)).reverse();
    }

    function _actions(n) {
        const out = [];
        for (const action of n.actions)
            out.push({ identifier: action.identifier, text: action.text });
        return out;
    }

    function _wrap(n) {
        return {
            id: n.id,
            app: n.appName.length > 0 ? n.appName : "notification",
            appIcon: n.appIcon,
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            time: notifs._times[n.id] ?? "",
            image: n.image,
            desktopEntry: n.desktopEntry,
            resident: n.resident,
            transient: n.transient,
            actions: _actions(n),
            hasInlineReply: n.hasInlineReply,
            replyPlaceholder: n.inlineReplyPlaceholder.length > 0 ? n.inlineReplyPlaceholder : "Write a reply..."
        };
    }

    function _find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function dismiss(id) {
        const n = _find(id);
        if (n)
            n.dismiss();
    }

    function invokeAction(id, identifier) {
        const n = _find(id);
        if (!n)
            return;
        for (const action of n.actions) {
            if (action.identifier === identifier) {
                action.invoke();
                return;
            }
        }
    }

    function sendInlineReply(id, text) {
        const n = _find(id);
        const reply = (text ?? "").trim();
        if (n && n.hasInlineReply && reply.length > 0)
            n.sendInlineReply(reply);
    }

    function clearAll() {
        const all = [...server.trackedNotifications.values];
        for (const n of all)
            n.dismiss();
    }
}
