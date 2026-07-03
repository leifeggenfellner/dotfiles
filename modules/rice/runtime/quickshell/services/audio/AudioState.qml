pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire

// ── AudioState — REAL ─────────────────────────────────────────
// Native Pipewire binding (D-008 tier 1): no polling, no CLI.
// Properties update when Pipewire reports the change, so shown
// state is real state.
//
//   state:    available, busy, error, mock, volume [0..1], muted
//   commands: setVolume(v), setMuted(m), toggleMuted()

Item {
    id: audio

    readonly property bool mock: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property bool busy: false
    readonly property string error: ""

    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false

    // Binding node properties requires tracking the node.
    PwObjectTracker {
        objects: audio.sink ? [audio.sink] : []
    }

    function setVolume(v) {
        if (available)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }
    function setMuted(m) {
        if (available)
            sink.audio.muted = m;
    }
    function toggleMuted() {
        setMuted(!muted);
    }
}
