pragma Singleton
import QtQuick

// ── AudioState — MOCK, replaced in Phase 5 ────────────────────
// Shape per contracts/service-contract.md:
//   state:    available, busy, error, volume [0..1], muted
//   commands: setVolume(v), setMuted(m), toggleMuted()
// Commands mutate mock state so UI exercises the real data flow.

Item {
    id: audio

    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property real volume: 0.42
    property bool muted: false

    function setVolume(v) {
        volume = Math.max(0, Math.min(1, v));
    }
    function setMuted(m) {
        muted = m;
    }
    function toggleMuted() {
        muted = !muted;
    }
}
