import Quickshell
import Quickshell.Io
import QtQuick
import "../../core"
import "../../services/prefs"

// ── DailyAccentController ────────────────────────────────────
// Daily accent (D-054): a theme may let a daily record recolour its
// primary accent for the day. `widgets.dailyAccent.settings`:
//
//   record   prefs path of the record { date, id?, index? }; must be
//            extras.<ns>.<key> (claimed once per day, D-042)
//   catalog  manifest path of the entries it resolves against (by id,
//            then position); an entry's `accent` is the day's colour
//
// Resolved here, pushed as plain data onto ShellState.dailyAccent, and
// read by Theme in place of accent.primary. Nothing is written: with no
// record for today, an entry without an accent, or no settings, the
// theme's own accent stands. The date is re-read every minute, so the
// accent returns at midnight. rice-cli tools resolve the same way
// (nix/_daily-lib.nix); Hyprland borders and HyprFM (D-055) follow
// through their adapters, re-run here when the accent changes within a
// theme (a theme switch re-runs them itself).
//
//   quickshell -c rice ipc call dailyAccent status

Item {
    id: controller

    readonly property var settings: Theme.widgetConfig("dailyAccent").settings ?? ({})
    readonly property var recordPath: typeof settings.record === "string" ? settings.record.split(".") : []
    readonly property bool configured: recordPath.length === 3 && recordPath[0] === "extras" && typeof settings.catalog === "string"

    property string today: _date()

    readonly property var entry: {
        if (!configured)
            return null;
        const record = PrefsState.extra(recordPath[1], recordPath[2], null);
        const catalog = _path(ManifestLoader.manifest, settings.catalog);
        if (!record || record.date !== today || !Array.isArray(catalog))
            return null;
        if (record.id !== undefined) {
            const byId = catalog.find(e => e && e.id === record.id);
            if (byId)
                return byId;
        }
        const position = record.index ?? record.card;
        return typeof position === "number" && position >= 0 && position < catalog.length ? catalog[position] : null;
    }
    readonly property string accent: entry && /^#[0-9a-fA-F]{6}$/.test(entry.accent ?? "") ? entry.accent : ""

    // Last value the compositor was given, and for which theme.
    property string _applied: ""
    property string _theme: ""
    property bool _settled: false

    function _date() {
        return Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    function _path(root, dotted) {
        return dotted.split(".").reduce((node, key) => node === null || node === undefined ? undefined : node[/^[0-9]+$/.test(key) ? Number(key) : key], root);
    }

    function _sync() {
        if (!PrefsState.ready || !ManifestLoader.loaded)
            return;
        const theme = Theme.activeName;
        if (_settled && theme === _theme && accent !== _applied) {
            // HyprFM takes the day's accent; window chrome never does (D-078).
            const env = "RICE_DAILY_ACCENT=" + (accent.length > 0 ? accent : "none");
            Quickshell.execDetached(["env", env, "rice-hyprfm-theme", "--active"]);
        }
        _settled = true;
        _theme = theme;
        _applied = accent;
    }

    Binding {
        target: ShellState
        property: "dailyAccent"
        value: controller.accent
    }

    // Batched so a theme switch is seen whole: settings, entry and the
    // active name all change before the comparison runs.
    onAccentChanged: Qt.callLater(_sync)
    Connections {
        target: PrefsState
        function onReadyChanged() {
            Qt.callLater(controller._sync);
        }
    }
    Connections {
        target: ManifestLoader
        function onLoadedChanged() {
            Qt.callLater(controller._sync);
        }
    }
    Component.onCompleted: Qt.callLater(_sync)

    Timer {
        interval: 60000
        repeat: true
        running: controller.configured
        onTriggered: controller.today = controller._date()
    }

    IpcHandler {
        target: "dailyAccent"

        function status(): string {
            return JSON.stringify({
                configured: controller.configured,
                today: controller.today,
                entry: controller.entry ? controller.entry.id ?? null : null,
                accent: controller.accent
            });
        }
    }
}
