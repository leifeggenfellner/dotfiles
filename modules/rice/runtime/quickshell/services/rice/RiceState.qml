pragma Singleton
import QtQuick
import Quickshell.Io

// ── RiceState — REAL ──────────────────────────────────────────
// Executes theme switches through rice-switch (D-003 layer 2: the
// tool owns pointer write + wallpaper orchestration; this service
// never touches those directly). Which themes exist and which is
// active is theme DATA — read from the Theme facade, not here
// (services never import core).
//
//   state:    available, busy, error
//   commands: switchTo(name)

Item {
    id: rice

    readonly property bool mock: false
    readonly property bool available: true
    property bool busy: false
    property string error: ""

    function switchTo(name) {
        if (busy || !name || name.length === 0)
            return;
        busy = true;
        error = "";
        proc.command = ["rice-switch", name];
        proc.running = true;
    }

    Process {
        id: proc
        onExited: (code, status) => {
            rice.busy = false;
            if (code !== 0)
                rice.error = "rice-switch failed (exit " + code + ")";
        }
    }
}
