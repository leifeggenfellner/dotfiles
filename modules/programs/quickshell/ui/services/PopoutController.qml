pragma Singleton
import QtQuick

// ── PopoutController ─────────────────────────────────────────
// Enforces single-open invariant for all bar popouts.
// Widgets call requestOpen(id) / toggle(id) / requestClose().
// Bind popup visibility to: PopoutController.activePopout === "my-id"

QtObject {
    id: controller

    property string activePopout: ""

    signal opened(string id)
    signal closed(string id)

    function requestOpen(id) {
        if (activePopout === id)
            return;
        if (activePopout !== "")
            closed(activePopout);
        activePopout = id;
        opened(id);
    }

    function requestClose() {
        if (activePopout === "")
            return;
        let prev = activePopout;
        activePopout = "";
        closed(prev);
    }

    function toggle(id) {
        if (activePopout === id)
            requestClose();
        else
            requestOpen(id);
    }

    function isOpen(id) {
        return activePopout === id;
    }
}
