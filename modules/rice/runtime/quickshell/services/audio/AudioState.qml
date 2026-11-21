pragma Singleton
import QtQuick
import QtQml
import Quickshell.Services.Pipewire

// ── AudioState — REAL ─────────────────────────────────────────
// Native Pipewire binding (D-008 tier 1): no polling, no CLI.
// Properties update when Pipewire reports the change, so shown
// state is real state. Devices and streams are the live PwNode
// objects (id, name, description, nickname, properties, audio).
//
//   state:    available, busy, error, mock,
//             volume [0..1], muted              (default output)
//             micAvailable, micVolume, micMuted (default input)
//             sink, source (default nodes), sinks[], sources[],
//             streams[] (apps playing), metering,
//             levels { nodeId: PwNodePeakMonitor } while metering
//             (read `.peak` [0..1]; the default input is included)
//   commands: setVolume(v), setMuted(m), toggleMuted(),
//             setMicVolume(v), setMicMuted(m), toggleMicMuted(),
//             setDefaultSink(id), setDefaultSource(id),
//             setStreamVolume(id, v), setStreamMuted(id, m),
//             setMetering(on)

Item {
    id: audio

    readonly property bool mock: false
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool available: sink !== null && sink.audio !== null
    readonly property bool busy: false
    readonly property string error: ""

    readonly property real volume: available ? sink.audio.volume : 0
    readonly property bool muted: available ? sink.audio.muted : false

    readonly property bool micAvailable: source !== null && source.audio !== null
    readonly property real micVolume: micAvailable ? source.audio.volume : 0
    readonly property bool micMuted: micAvailable ? source.audio.muted : false

    readonly property var _nodes: Pipewire.nodes ? Pipewire.nodes.values : []
    // Type flags come with the node; `properties` only once it is tracked.
    readonly property var sinks: _nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: _nodes.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: _nodes.filter(n => n.type === PwNodeType.AudioOutStream)

    property bool metering: false
    property var levels: ({})

    // Binding node audio properties requires tracking the nodes.
    PwObjectTracker {
        objects: [audio.sink, audio.source].filter(n => n !== null).concat(audio.streams)
    }

    function _node(id) {
        return _nodes.find(n => n.id === id) ?? null;
    }

    // ── commands ──────────────────────────────────────────────
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

    function setMicVolume(v) {
        if (micAvailable)
            source.audio.volume = Math.max(0, Math.min(1, v));
    }
    function setMicMuted(m) {
        if (micAvailable)
            source.audio.muted = m;
    }
    function toggleMicMuted() {
        setMicMuted(!micMuted);
    }

    function setDefaultSink(id) {
        const n = _node(id);
        if (n)
            Pipewire.preferredDefaultAudioSink = n;
    }
    function setDefaultSource(id) {
        const n = _node(id);
        if (n)
            Pipewire.preferredDefaultAudioSource = n;
    }

    function setStreamVolume(id, v) {
        const n = _node(id);
        if (n && n.audio)
            n.audio.volume = Math.max(0, Math.min(1, v));
    }
    function setStreamMuted(id, m) {
        const n = _node(id);
        if (n && n.audio)
            n.audio.muted = m;
    }

    // Level meters cost a little CPU; a page turns them on while open.
    function setMetering(on) {
        metering = on;
    }

    Instantiator {
        model: audio.metering ? [audio.source].filter(n => n !== null).concat(audio.streams) : []
        delegate: PwNodePeakMonitor {
            required property var modelData
            node: modelData
            enabled: true
        }
        onObjectAdded: (index, object) => {
            const next = Object.assign({}, audio.levels);
            next[object.modelData.id] = object;
            audio.levels = next;
        }
        onObjectRemoved: (index, object) => {
            const next = Object.assign({}, audio.levels);
            delete next[object.modelData.id];
            audio.levels = next;
        }
    }
}
