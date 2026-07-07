import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/prefs"

// ── SoundController ──────────────────────────────────────────
// Modules-layer bridge for durable sound prefs: services own the
// file, core owns the Sound facade, and ShellState carries the
// read-only gate between them.

Item {
    Binding {
        target: ShellState
        property: "soundMuted"
        value: PrefsState.soundMuted
    }

    IpcHandler {
        target: "sound"

        function status(): string {
            return JSON.stringify({ muted: PrefsState.soundMuted, error: Sound.error });
        }
        function setMuted(v: string): void {
            PrefsState.setSoundMuted(v === "on" || v === "true" || v === "1");
        }
        function toggleMuted(): void {
            PrefsState.setSoundMuted(!PrefsState.soundMuted);
        }
        function test(eventName: string): void {
            Sound.play(eventName.length > 0 ? eventName : "notification");
        }
    }
}
