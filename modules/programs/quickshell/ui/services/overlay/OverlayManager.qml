pragma Singleton
import QtQuick

QtObject {
    id: manager

    // ── Overlay type constants ───────────────────────────────
    readonly property int typeTooltip: 1
    readonly property int typeNotify: 2   // reserved for future
    readonly property int typeCommand: 3

    // ── Active overlay registry ──────────────────────────────
    // Each entry: { id, type, anchor, screenKey, desiredX, desiredY, width, height, visible }
    property var overlays: []

    // ── Signals ──────────────────────────────────────────────
    signal requestResolve()

    // ── Lifecycle ────────────────────────────────────────────

    function push(cfg) {
        let entry = {
            id: cfg.id || _nextId(),
            type: cfg.type || typeTooltip,
            anchor: cfg.anchor || "top-right",
            screenKey: cfg.screenKey || "",
            desiredX: cfg.desiredX || 0,
            desiredY: cfg.desiredY || 0,
            width: cfg.width || 0,
            height: cfg.height || 0,
            visible: true
        };
        overlays = overlays.concat([entry]);
        requestResolve();
        return entry.id;
    }

    function update(id, props) {
        let list = overlays;
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                let keys = Object.keys(props);
                for (let k = 0; k < keys.length; k++)
                    list[i][keys[k]] = props[keys[k]];
                overlays = list;
                requestResolve();
                return;
            }
        }
    }

    function remove(id) {
        overlays = overlays.filter(function(o) { return o.id !== id; });
        requestResolve();
    }

    function clearTransient(screenKey) {
        overlays = overlays.filter(function(o) {
            return o.screenKey !== screenKey || o.type === typeCommand;
        });
        requestResolve();
    }

    function find(id) {
        for (let i = 0; i < overlays.length; i++) {
            if (overlays[i].id === id)
                return overlays[i];
        }
        return null;
    }

    // ── Internal ─────────────────────────────────────────────
    property int _counter: 0
    function _nextId() {
        _counter++;
        return "__overlay_" + _counter;
    }
}
