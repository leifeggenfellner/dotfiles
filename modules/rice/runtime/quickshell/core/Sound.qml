pragma Singleton
import QtQuick
import Quickshell.Io

// ── Sound — REAL, DEFAULT MUTED ──────────────────────────────
// Theme-neutral user-event sound facade. Callers name semantic
// events; Theme resolves them to assets and ShellState gates mute.
// Playback is deliberately command-backed so the Quickshell runtime
// does not gain an undeclared QtMultimedia import dependency.
//
//   state:    available, muted
//   commands: play(eventName)

Item {
    id: sound

    readonly property bool mock: false
    readonly property bool available: true
    readonly property bool muted: ShellState.soundMuted
    property string error: ""

    function play(eventName) {
        if (muted || !eventName || eventName.length === 0)
            return false;

        const url = Theme.soundUrl(eventName);
        if (url.length === 0)
            return false;

        const path = _filePath(url);
        if (path.length === 0)
            return false;

        error = "";
        player.command = ["rice-sound-play", path];
        player.running = true;
        return true;
    }

    function _filePath(url) {
        if (url.startsWith("file://"))
            return decodeURIComponent(url.slice(7));
        if (url.startsWith("/"))
            return url;
        console.warn("Sound: unsupported sound url", url);
        return "";
    }

    Process {
        id: player
        onExited: (code, status) => {
            if (code !== 0)
                sound.error = "sound playback failed (exit " + code + ")";
        }
    }
}
