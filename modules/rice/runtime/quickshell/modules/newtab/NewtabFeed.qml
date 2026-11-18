import Quickshell
import Quickshell.Io
import QtQuick
import "../../core"
import "../../services/prefs"
import "../../services/weather"

// ── NewtabFeed ───────────────────────────────────────────────
// The browser's new-tab page (D-060) is a static file built per theme;
// this writes the live part beside it, as a script the page loads:
//
//   $XDG_STATE_HOME/rice/newtab-feed.js
//   window.riceNewtab = { updated, theme, weather, moon, sky, omen }
//
// Real values only: weather is null until WeatherState has a reading,
// and `omen` is the day's record formatted with
// `widgets.newtab.settings.daily = { record, catalog, format,
// pendingLabel }` (resolved like the terminal greeting, D-042), or the
// pending label when today has no record. Themes without
// `widgets.newtab.settings` get no file. Rewritten when any input
// changes (settled for a second) and every half hour.

Item {
    id: feed

    readonly property var settings: Theme.widgetConfig("newtab").settings ?? null
    readonly property var daily: feed.settings?.daily ?? null

    readonly property string path: {
        const env = Quickshell.env("XDG_STATE_HOME");
        const state = env && env.length > 0 ? env : Quickshell.env("HOME") + "/.local/state";
        return state + "/rice/newtab-feed.js";
    }

    property string today: _date()

    readonly property string omen: {
        const d = feed.daily;
        if (!d || typeof d.record !== "string" || typeof d.catalog !== "string")
            return "";
        const pending = typeof d.pendingLabel === "string" ? d.pendingLabel : "";
        const parts = d.record.split(".");
        if (parts.length !== 3 || parts[0] !== "extras")
            return pending;
        const record = PrefsState.extra(parts[1], parts[2], null);
        const catalog = _path(ManifestLoader.manifest, d.catalog);
        if (!record || record.date !== feed.today || !Array.isArray(catalog))
            return pending;
        let entry = record.id !== undefined ? catalog.find(e => e && e.id === record.id) : null;
        const position = record.index ?? record.card;
        if (!entry && typeof position === "number" && position >= 0 && position < catalog.length)
            entry = catalog[position];
        if (!entry)
            return pending;
        const format = typeof d.format === "string" ? d.format : "{name}";
        return format.replace(/\{([A-Za-z0-9_]+)\}/g, (match, key) => entry[key] !== undefined ? String(entry[key]) : match);
    }

    readonly property var payload: ({
            theme: Theme.activeName,
            weather: WeatherState.available ? {
                location: WeatherState.location,
                condition: WeatherState.condition,
                temperatureC: Math.round(WeatherState.temperatureC),
                feelsLikeC: Math.round(WeatherState.feelsLikeC),
                kind: WeatherState.kind
            } : null,
            moon: {
                name: WeatherState.moonName,
                illumination: Math.round(WeatherState.moonIllumination * 100)
            },
            sky: ShellState.skyConditions,
            omen: feed.omen
        })

    onPayloadChanged: settle.restart()
    onSettingsChanged: settle.restart()

    Connections {
        target: PrefsState
        function onReadyChanged() {
            settle.restart();
        }
    }
    Connections {
        target: ManifestLoader
        function onLoadedChanged() {
            settle.restart();
        }
    }

    function _date() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function _path(root, dotted) {
        return dotted.split(".").reduce((node, key) => node === null || node === undefined ? undefined : node[/^[0-9]+$/.test(key) ? Number(key) : key], root);
    }

    function _write() {
        if (!feed.settings || !ManifestLoader.loaded || !PrefsState.ready)
            return;
        const data = Object.assign({ updated: new Date().toISOString() }, feed.payload);
        file.setText("window.riceNewtab = " + JSON.stringify(data) + ";\n");
    }

    Timer {
        id: settle
        interval: 1000
        onTriggered: feed._write()
    }

    // Keeps the date (and so the omen) and `updated` current.
    Timer {
        interval: 1800000
        repeat: true
        running: feed.settings !== null
        onTriggered: {
            feed.today = feed._date();
            feed._write();
        }
    }

    Component.onCompleted: {
        if (feed.settings && !WeatherState.available)
            WeatherState.refresh();
    }

    FileView {
        id: file
        path: feed.path
        // Written, never read.
        preload: false
        atomicWrites: true
        onSaveFailed: error => console.warn("NewtabFeed: failed to write", feed.path, "-", error)
    }
}
