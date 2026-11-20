import QtQuick
import Quickshell.Io

// ── BurnEffect ───────────────────────────────────────────────
// A layer effect that burns its item away (D-082): set on an item's
// layer.effect and drive `progress` from 0 (whole) to 1 (gone). It
// needs the compiled burn shader; `ready` is false without it (dev
// runs), and callers fade instead.

ShaderEffect {
    id: effect

    property real progress: 0
    property color ember: "orange"
    property color soot: "black"
    property vector2d resolution: Qt.vector2d(Math.max(1, width), Math.max(1, height))

    readonly property bool ready: _ready
    property bool _ready: false

    fragmentShader: _ready ? Qt.resolvedUrl("shaders/burn.qsb") : ""

    FileView {
        path: String(Qt.resolvedUrl("shaders/manifest.json")).replace(/^file:\/\//, "")
        watchChanges: false
        onLoaded: {
            try {
                effect._ready = (JSON.parse(text()).compiled ?? []).includes("burn");
            } catch (e) {
                effect._ready = false;
            }
        }
    }
}
