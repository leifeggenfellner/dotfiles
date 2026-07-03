import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/notifications"

// ── NotificationIpc ───────────────────────────────────────────
// Single-instance IPC endpoint for notification commands (kept out
// of ShellState: core may not import services). Instantiated once
// in shell.qml — never inside per-screen Variants, IPC targets must
// be unique.

Item {
    IpcHandler {
        target: "notifications"

        function clearAll(): void {
            NotificationState.clearAll();
        }
        function toggleCenter(): void {
            ShellState.toggleNotifications();
        }
    }
}
