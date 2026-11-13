import QtQuick
import Quickshell.Io
import "../../services/prefs"

// ── PrefsIpc ─────────────────────────────────────────────────
// Narrow IPC for out-of-shell consumers that need a durable pref
// written: PrefsState stays the sole writer of prefs.json (D-042).
// Only the first-writer-per-day claim is exposed, never raw writes.
//
//   quickshell -c rice ipc call prefs claimDaily <ns> <key> '<json>'
//     → effective record as JSON, or "" when the request is invalid

Item {
    IpcHandler {
        target: "prefs"

        function claimDaily(namespace: string, key: string, record: string): string {
            if (!namespace || !key)
                return "";
            let parsed = null;
            try {
                parsed = JSON.parse(record);
            } catch (e) {
                return "";
            }
            if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed))
                return "";
            const effective = PrefsState.claimDaily(namespace, key, parsed);
            return effective ? JSON.stringify(effective) : "";
        }
    }
}
