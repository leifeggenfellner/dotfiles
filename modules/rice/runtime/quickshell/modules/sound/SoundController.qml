import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/hypr"
import "../../services/prefs"

// ── SoundController ──────────────────────────────────────────
// Modules-layer bridge for durable sound prefs: services own the
// file, core owns the Sound facade, and ShellState carries the
// read-only gate between them.
//
// It also plays the shell-wide cues (D-057) on user-driven edges:
// launcher-open, power-open and workspace. Startup
// hydration plays nothing; a workspace that has a mood with its own
// sound (D-045) leaves the entry to the mood.

Item {
    id: controller

    property bool _settled: false
    property int _workspace: -1

    Timer {
        interval: 1500
        running: true
        onTriggered: {
            controller._workspace = HyprState.activeWorkspace;
            controller._settled = true;
        }
    }

    Connections {
        target: ShellState
        function onLauncherOpenChanged() {
            if (ShellState.launcherOpen)
                Sound.play("launcher-open");
        }
        function onActivePopoutChanged() {
            if (ShellState.activePopout === "power")
                Sound.play("power-open");
        }
    }

    Connections {
        target: HyprState
        function onActiveWorkspaceChanged() {
            if (controller._settled)
                Qt.callLater(controller._workspaceCue);
        }
    }

    // Deferred so ShellState.moods has caught up with the switch.
    function _workspaceCue() {
        const id = HyprState.activeWorkspace;
        if (id <= 0 || id === _workspace)
            return;
        _workspace = id;
        for (const screen in ShellState.moods) {
            const mood = ShellState.moods[screen];
            if (mood.sound && String(mood.workspace) === String(id))
                return;
        }
        // Rapid switching whispers once, never a stack.
        Sound.play("workspace", 400);
    }

    Binding {
        target: ShellState
        property: "soundMuted"
        value: PrefsState.soundMuted
    }
    Binding {
        target: ShellState
        property: "soundOff"
        value: PrefsState.soundOff
    }

    IpcHandler {
        target: "sound"

        function status(): string {
            return JSON.stringify({ muted: PrefsState.soundMuted, off: PrefsState.soundOff, error: Sound.error });
        }
        function setMuted(v: string): void {
            PrefsState.setSoundMuted(v === "on" || v === "true" || v === "1");
        }
        function toggleMuted(): void {
            PrefsState.setSoundMuted(!PrefsState.soundMuted);
        }
        // Silence or restore one cue: setCue workspace off
        function setCue(cue: string, v: string): void {
            PrefsState.setSoundCue(cue, v === "on" || v === "true" || v === "1");
        }
        function test(eventName: string): void {
            Sound.play(eventName.length > 0 ? eventName : "notification");
        }
    }
}
