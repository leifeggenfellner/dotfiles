pragma Singleton
import QtQuick
import Quickshell.Services.SystemTray

// ── TrayState — REAL ──────────────────────────────────────────
// StatusNotifier items via Quickshell's native SystemTray
// (D-008 tier 1). Live item objects: id, title, icon (image URL),
// tooltipTitle, activate(), secondaryActivate(), native menu display.
//
//   state:    available, mock, items[]
//   commands: activate(id), secondaryActivate(id), displayMenu(id, window, x, y)

Item {
    id: tray

    readonly property bool mock: false
    readonly property bool available: true
    readonly property var items: SystemTray.items.values

    function itemById(id) {
        return items.find(i => i.id === id) ?? null;
    }

    function activate(id) {
        const it = itemById(id);
        if (it)
            it.activate();
    }

    function secondaryActivate(id) {
        const it = itemById(id);
        if (it)
            it.secondaryActivate();
    }

    function displayMenu(id, parentWindow, relativeX, relativeY) {
        const it = itemById(id);
        if (!it || !it.hasMenu || !parentWindow)
            return false;
        it.display(parentWindow, relativeX, relativeY);
        return true;
    }
}
