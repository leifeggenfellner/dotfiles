import QtQuick
import Quickshell.Io

// ── WallpaperIpc ──────────────────────────────────────────────
// IPC surface for wallpaper commands. Lives once in shell.qml
// (IPC targets must be unique — never inside Variants). Module
// layer because the commands need Theme + services (see
// WallpaperCommands).
//
//   quickshell -c rice ipc call wallpapers next

Item {
    IpcHandler {
        target: "wallpapers"

        function next(): void {
            WallpaperCommands.next();
        }
    }
}
