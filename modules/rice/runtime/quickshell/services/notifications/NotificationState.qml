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
//             notifications[] {id, app, summary, body, urgency, time}
//   commands: dismiss(id), clearAll()
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
        bodySupported: true
        actionsSupported: true

        onNotification: n => {
            n.tracked = true;
            notifs._times[n.id] = Qt.formatTime(new Date(), "HH:mm");
            notifs._timesBump++;
            notifs.received({
                id: n.id,
                app: n.appName.length > 0 ? n.appName : "notification",
                summary: n.summary,
                body: n.body,
                urgency: n.urgency,
                time: notifs._times[n.id]
            });
        }
    }

    // Same wrapper shape the mock had, newest first — consumers
    // were built against it and need no changes.
    readonly property var notifications: {
        void notifs._timesBump;
        return server.trackedNotifications.values.map(n => ({
            id: n.id,
            app: n.appName.length > 0 ? n.appName : "notification",
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            time: notifs._times[n.id] ?? ""
        })).reverse();
    }

    function _find(id) {
        return server.trackedNotifications.values.find(n => n.id === id) ?? null;
    }

    function dismiss(id) {
        const n = _find(id);
        if (n)
            n.dismiss();
    }

    function clearAll() {
        const all = [...server.trackedNotifications.values];
        for (const n of all)
            n.dismiss();
    }
}
