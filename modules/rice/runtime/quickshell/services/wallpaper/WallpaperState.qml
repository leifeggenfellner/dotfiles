pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// WallpaperState - REAL
// Wraps the existing awww flow (services/hyprpaper.nix): the
// persist file ~/.config/wallpaper/current is the source of truth,
// shared with the wallpaper-restore/wallpaper-picker scripts.
// Watching it keeps `current` correct no matter who changes it.
//
//   state:    available, busy, error, mock, current
//   commands: setWallpaper(path)
// Wallpaper choices (per-theme lists) are theme data, composed
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
        applyProcess.command = ["sh", "-c", 'wallpaper-apply "$1" fade 1.0', "wallpaper-set", path];
        applyProcess.running = true;
    }

    Process {
        id: applyProcess
        onExited: function (code, status) {
            wallpaper.busy = false;
            if (code !== 0) {
                wallpaper.error = "wallpaper apply failed (exit " + code + ")";
            } else {
                // A watch set while the persist file was missing does
                // not fire on creation; reload after our own write.
                persistFile.reload();
            }
        }
    }

    FileView {
        id: persistFile
        path: wallpaper.persistPath
        watchChanges: true
        onLoaded: wallpaper.current = text().trim()
        onFileChanged: reload()
        onLoadFailed: wallpaper.current = ""
    }
}
