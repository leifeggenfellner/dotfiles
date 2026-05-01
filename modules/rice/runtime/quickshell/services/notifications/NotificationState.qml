pragma Singleton
import QtQuick

// ── NotificationState — MOCK, replaced in Phase 6 ─────────────
// Shape per contracts/service-contract.md:
//   state:    available, busy, error, notifications[]
//   commands: dismiss(id), clearAll()
// Phase 6 moves this onto Quickshell's notification server.

Item {
    id: notifs

    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property var notifications: [
        { id: 1, app: "Mail", summary: "3 new messages", body: "Inbox updated", time: "09:12" },
        { id: 2, app: "Updates", summary: "System update available", body: "12 packages", time: "08:47" },
        { id: 3, app: "Calendar", summary: "Standup in 15 min", body: "Daily sync", time: "08:45" }
    ]

    function dismiss(id) {
        notifications = notifications.filter(n => n.id !== id);
    }
    function clearAll() {
        notifications = [];
    }
}
