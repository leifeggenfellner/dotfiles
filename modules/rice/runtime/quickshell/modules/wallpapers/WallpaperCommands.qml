pragma Singleton
import QtQuick
import "../../core"
import "../../services/wallpaper"
import "../../services/prefs"

// ── WallpaperCommands ─────────────────────────────────────────
// The single apply path for wallpaper changes (D-019): set the
// wallpaper AND record it as the active theme's last-used in one
// deterministic, user-initiated step. Module layer on purpose —
// it needs Theme (core) plus two services, which no lower layer
// may combine. Observation-based recording was rejected: during a
// rice switch the pointer and persist-file reloads race, and a
// stale activeName would corrupt the OLD theme's memory.

QtObject {
    function apply(path) {
        if (!path || path.length === 0)
            return;
        WallpaperState.setWallpaper(path);
        PrefsState.recordWallpaper(Theme.activeName, path);
    }

    // Step to the next wallpaper in the active theme's set; wraps.
    // Current wallpaper not in the set (or unset) → start at 0.
    function next() {
        const list = Theme.wallpapers;
        if (!list || list.length === 0)
            return;
        const idx = list.indexOf(WallpaperState.current);
        apply(list[(idx + 1) % list.length]);
    }
}
