import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/notifications"
import "../../services/prefs"

// ── NotificationIpc ───────────────────────────────────────────
// Single-instance IPC endpoint for notification commands (kept out
// of ShellState: core may not import services). Instantiated once
// in shell.qml — never inside per-screen Variants, IPC targets must
// be unique.

Item {
    Binding {
        target: ShellState
        property: "doNotDisturb"
        value: PrefsState.doNotDisturb
    }

    IpcHandler {
        target: "notifications"

        function status(): string {
            return JSON.stringify({
                count: NotificationState.notifications.length,
                doNotDisturb: PrefsState.doNotDisturb
            });
        }

        function clearAll(): void {
            NotificationState.clearAll();
        }
        function toggleCenter(): void {
            ShellState.toggleNotifications();
        }
        function setDnd(v: string): void {
            PrefsState.setDoNotDisturb(v === "on" || v === "true" || v === "1");
        }
        function toggleDnd(): void {
            PrefsState.setDoNotDisturb(!PrefsState.doNotDisturb);
        }
    }
}
