pragma Singleton
import Quickshell
import QtQuick
import "../../utils"

// ── AppsState — REAL ──────────────────────────────────────────
// Desktop application catalog backed by Quickshell DesktopEntries
// (D-008 tier 1: native API). The service exposes a stable visible
// list plus launch/search commands so surfaces do not bind directly
// to DesktopEntries' model details.
//
//   state:    available, apps, error
//   commands: search(query, limit), launch(app)

Item {
    id: appsState

    readonly property bool mock: false
    readonly property bool available: true
    property string error: ""

    readonly property var apps: _visibleApps(DesktopEntries.applications.values)

    function search(query, limit) {
        const max = limit ?? 24;
        const normalized = Fuzzy.normalize(query);
        const ranked = [];
        const list = apps;
        for (let i = 0; i < list.length; i++) {
            const app = list[i];
            const score = normalized.length === 0 ? (1000 - i) : Fuzzy.bestScore(_fields(app), normalized);
            if (score >= 0)
                ranked.push(_row(app, score));
        }
        ranked.sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));
        return ranked.slice(0, max);
    }

    function launch(app) {
        if (!app)
            return;
        error = "";
        try {
            app.execute();
        } catch (e) {
            error = "failed to launch " + (app.name || "application");
            console.warn("AppsState:", error, e);
        }
    }

    function _visibleApps(values) {
        const result = [];
        for (let i = 0; i < values.length; i++) {
            const app = values[i];
            if (!app || app.noDisplay || !app.name || app.name.length === 0)
                continue;
            result.push(app);
        }
        result.sort((a, b) => String(a.name).localeCompare(String(b.name)));
        return result;
    }

    function _fields(app) {
        return [app.name, app.genericName, app.comment, app.id, app.startupClass, app.categories, app.keywords];
    }

    function _row(app, score) {
        const subtitle = app.genericName && app.genericName.length > 0 ? app.genericName : app.comment;
        const rawIcon = app.icon && app.icon.length > 0 ? Quickshell.iconPath(app.icon, true) : "";
        const iconPath = rawIcon && rawIcon.startsWith("/") ? "file://" + rawIcon : rawIcon;
        return {
            app: app,
            score: score,
            id: app.id,
            name: app.name,
            subtitle: subtitle ?? "",
            iconName: app.icon ?? "",
            iconPath: iconPath ?? ""
        };
    }
}
