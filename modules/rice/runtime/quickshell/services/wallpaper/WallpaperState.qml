pragma Singleton
import QtQuick

// ── WallpaperState — MOCK, replaced in Phase 5 ────────────────
// Shape per contracts/service-contract.md:
//   state:    available, busy, error, current, wallpapers[]
//   commands: setWallpaper(path)
// Phase 5 wraps the existing awww/wallpaper-restore flow.

Item {
    id: wallpaper

    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property string current: ""
    property var wallpapers: []

    function setWallpaper(path) {
        current = path;
    }
}
