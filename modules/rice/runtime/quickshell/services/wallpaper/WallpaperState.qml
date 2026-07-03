pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ── WallpaperState — REAL ─────────────────────────────────────
// Wraps the existing awww flow (services/hyprpaper.nix): the
// persist file ~/.config/wallpaper/current is the source of truth,
// shared with the wallpaper-restore/wallpaper-picker scripts.
// Watching it keeps `current` correct no matter who changes it.
//
//   state:    available, busy, error, mock, current
//   commands: setWallpaper(path)
// Wallpaper *choices* (per-theme lists) are theme data — composed
// by surfaces from the manifest, never known to this service.

Item {
    id: wallpaper

    readonly property bool mock: false
    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property string current: ""

    readonly property string persistPath: Quickshell.env("HOME") + "/.config/wallpaper/current"

    function setWallpaper(path) {
        if (busy || !path || path.length === 0)
            return;
        busy = true;
        error = "";
        // Positional-arg passing keeps arbitrary paths injection-safe.
        _apply.command = ["sh", "-c",
            'awww img "$1" --transition-type fade --transition-duration 1.0 --transition-fps 60'
            + ' && mkdir -p "$(dirname "$2")" && printf %s "$1" > "$2"',
            "awww-set", path, wallpaper.persistPath];
        _apply.running = true;
    }

    Process {
        id: _apply
        onExited: (code, status) => {
            wallpaper.busy = false;
            if (code !== 0)
                wallpaper.error = "wallpaper apply failed (exit " + code + ")";
        }
    }

    FileView {
        path: wallpaper.persistPath
        watchChanges: true
        onLoaded: wallpaper.current = text().trim()
        onFileChanged: reload()
        onLoadFailed: wallpaper.current = ""
    }
}
