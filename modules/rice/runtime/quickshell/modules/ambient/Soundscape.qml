import QtQuick
import Quickshell.Io
import "../../core"

// ── Soundscape ───────────────────────────────────────────────
// The ambient sound bed (D-058): long loops a theme lists in
// `widgets.soundscape.settings.layers`, mixed by one managed
// rice-soundscape-play process. Whether it may run at all is the
// governor's call (`allowed`); this item only decides which layers
// the moment asks for:
//
//   sound   an assets.sounds name, looped
//   volume  0–1 within the bed (default 1)
//   when    a sky condition (D-046) the layer waits for
//   mood    a workspace mood (D-045) the layer belongs to; while a
//           screen shows that workspace its layers replace the rest
//
// Changes settle for a moment before the player restarts, so passing
// through a workspace or a flicker of media doesn't stutter the bed.
// Off means no process at all.

Item {
    id: bed

    property bool allowed: false

    readonly property var layers: (Theme.widgetConfig("soundscape").settings ?? ({})).layers ?? []

    readonly property var chosen: {
        const shown = Object.values(ShellState.moods).map(m => m.workspace);
        const live = bed.layers.filter(l => !l.when || ShellState.skyHas(l.when));
        const moodLayers = live.filter(l => l.mood && shown.includes(l.mood));
        return moodLayers.length > 0 ? moodLayers : live.filter(l => !l.mood);
    }

    readonly property var args: {
        const out = [];
        for (const layer of bed.chosen) {
            const file = Sound.path(layer.sound);
            if (file.length > 0)
                out.push(String(Math.max(0, Math.min(1, layer.volume ?? 1))), file);
        }
        return out;
    }

    readonly property var wanted: bed.allowed ? bed.args : []
    readonly property bool playing: player.running
    readonly property var playingLayers: bed._playing
    property string error: ""

    property var _playing: []
    property var _next: []
    property bool _stopping: false

    onWantedChanged: settle.restart()

    Timer {
        id: settle
        interval: 800
        onTriggered: {
            bed._next = bed.wanted;
            if (JSON.stringify(bed._next) === JSON.stringify(player.running ? player.command.slice(1) : []))
                return;
            if (player.running) {
                bed._stopping = true;
                player.running = false;
            } else {
                bed._start();
            }
        }
    }

    function _start() {
        bed._playing = [];
        if (bed._next.length === 0)
            return;
        bed.error = "";
        player.command = ["rice-soundscape-play"].concat(bed._next);
        bed._playing = bed.chosen.map(l => l.sound);
        player.running = true;
    }

    Process {
        id: player
        // Stopped on purpose (SIGTERM fades out) → start whatever is
        // wanted now. Ending by itself is a failure, which stays down
        // until the next change rather than looping.
        onExited: (code, status) => {
            if (bed._stopping) {
                bed._stopping = false;
                bed._start();
                return;
            }
            bed.error = "soundscape playback ended (exit " + code + ")";
            bed._playing = [];
        }
    }
}
