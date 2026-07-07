pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ── PrefsState — REAL ─────────────────────────────────────────
// Sole WRITER of $XDG_STATE_HOME/rice/prefs.json (D-019). Durable
// user drift that is not theme data and not system state: last-used
// wallpaper per theme, plus global motion prefs (D-021/D-022).
// rice-switch READS the file at switch time; nothing else touches it.
//
// Theme-blind by layer rule (services never import core): callers
// pass the theme name as an opaque key — the module-layer
// WallpaperCommands supplies Theme.activeName.
//
//   state:    available, lastWallpaper(theme),
//             reduceMotion, ambientMode ("auto" | "off")
//   commands: recordWallpaper(theme, path),
//             setReduceMotion(on), setAmbientMode(mode)

Item {
    id: prefs

    readonly property bool mock: false
    readonly property bool available: true

    property var _data: ({ schemaVersion: 1, wallpapers: {} })

    readonly property string prefsPath: {
        const env = Quickshell.env("XDG_STATE_HOME");
        return (env && env.length > 0 ? env : Quickshell.env("HOME") + "/.local/state") + "/rice/prefs.json";
    }

    function lastWallpaper(theme) {
        return (_data.wallpapers ?? {})[theme] ?? "";
    }

    // Motion prefs (D-021/D-022). Read by modules/ambient/
    // AmbientController, which pushes them onto ShellState.
    readonly property bool reduceMotion: (_data.motion ?? {}).reduce ?? false
    readonly property string ambientMode: (_data.motion ?? {}).ambient ?? "auto"

    function setReduceMotion(on) {
        _writeMotion("reduce", !!on);
    }

    function setAmbientMode(mode) {
        if (mode !== "auto" && mode !== "off") {
            console.warn("PrefsState: ambient mode must be 'auto' or 'off', got", mode);
            return;
        }
        _writeMotion("ambient", mode);
    }

    function _writeMotion(key, value) {
        if (((_data.motion ?? {})[key] ?? null) === value)
            return;
        const next = JSON.parse(JSON.stringify(_data));
        next.motion = next.motion ?? {};
        next.motion[key] = value;
        prefs._data = next;
        file.setText(JSON.stringify(next, null, 2) + "\n");
    }

    function recordWallpaper(theme, path) {
        if (!theme || theme.length === 0 || !path || path.length === 0)
            return;
        if ((_data.wallpapers ?? {})[theme] === path)
            return;
        const next = JSON.parse(JSON.stringify(_data));
        next.wallpapers = next.wallpapers ?? {};
        next.wallpapers[theme] = path;
        prefs._data = next;
        file.setText(JSON.stringify(next, null, 2) + "\n");
    }

    FileView {
        id: file
        path: prefs.prefsPath
        watchChanges: true
        atomicWrites: true
        onLoaded: {
            try {
                prefs._data = JSON.parse(text());
            } catch (e) {
                console.warn("PrefsState: invalid prefs.json:", e);
            }
        }
        // Missing file: keep defaults — it appears on first record.
        onLoadFailed: {}
        onFileChanged: reload()
        onSaveFailed: error => console.warn("PrefsState: failed to write", prefs.prefsPath, "-", error)
    }
}
