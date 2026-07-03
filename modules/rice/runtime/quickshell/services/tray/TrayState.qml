pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

// ── TrayState — REAL ──────────────────────────────────────────
// StatusNotifier items via Quickshell's native SystemTray
// (D-008 tier 1). Live item objects: id, title, icon (image URL),
// tooltipTitle, activate(). Context menus are not exposed yet
// (activate-only, v1).
//
//   state:    available, mock, items[]
//   commands: activate(id)

Item {
    id: tray

    readonly property bool mock: false
    readonly property bool available: true
    readonly property var items: SystemTray.items.values

    function activate(id) {
        const it = items.find(i => i.id === id);
        if (it)
            it.activate();
    }
}
