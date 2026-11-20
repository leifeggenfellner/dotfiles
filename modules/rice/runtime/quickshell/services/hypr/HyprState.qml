pragma Singleton
import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland

// ── HyprState — REAL (partial) ────────────────────────────────
// Compositor state via Quickshell's native Hyprland binding
// (D-008 tier 1: no polling, no CLI). Deliberately minimal —
// only what surfaces need today. Grows in Phase 5+ (workspaces,
// window title) by porting from the legacy tree.
//
//   state:    available, focusedScreenName ("" when unknown),
//             activeWorkspace (id), activeWorkspaceForScreen(name),
//             activeWorkspaceNames ({ screenName: workspace name }),
//             anyFullscreen, monitorsRevision,
//             workspaceWindows ({ id: window count }, only workspaces
//             that exist), urgentWorkspaces ({ id: true }),
//             workspaceApps(id) (app ids of its windows, in order),
//             workspaceLayout(id) (its windows placed on its monitor,
//             for a miniature; null when unknown),
//             windowFrames(screenName) (the windows of the screen's
//             active workspace, for chrome drawn over them)
//   events:   workspaceSwitched(screenName, id) — a screen that already
//             showed a workspace moved to another (not the first report)
//   commands: switchWorkspace(id), moveFocusedWindow(id),
//             refreshWindows() (re-reads window geometry; Hyprland only
//             pushes it on request)
//
// Focused output is exposed by NAME (matches ShellScreen.name);
// HyprlandMonitor.screen is not reliable on this Quickshell version.
//
// anyFullscreen comes from the Wayland foreign-toplevel protocol
// (compositor-agnostic; the Hyprland module exposes no fullscreen
// fact). Per-toplevel `fullscreen` is not a model role, so the
// Instantiator below attaches a watcher per toplevel and recounts
// on change — event-driven, zero polling. Screen-agnostic for now:
// per-monitor granularity waits for a consumer that needs it.

Item {
    id: hypr

    readonly property bool mock: false
    readonly property bool available: Hyprland.focusedMonitor !== null
    readonly property string focusedScreenName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    readonly property int activeWorkspace: activeWorkspaceForScreen(focusedScreenName)

    property int _fullscreenCount: 0
    readonly property bool anyFullscreen: _fullscreenCount > 0
    property int monitorsRevision: 0
    property var _activeWorkspaces: ({})
    // Named workspaces ("focus") have negative ids, so consumers that
    // key on a workspace by name read this map instead.
    property var activeWorkspaceNames: ({})
    property var workspaceWindows: ({})
    property var urgentWorkspaces: ({})

    signal workspaceSwitched(string screenName, int workspaceId)

    function activeWorkspaceForScreen(screenName) {
        return hypr._activeWorkspaces[screenName] ?? Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
    }

    function _setActiveWorkspace(screenName, workspaceId) {
        if (!screenName || hypr._activeWorkspaces[screenName] === workspaceId)
            return;
        const known = screenName in hypr._activeWorkspaces;
        hypr._activeWorkspaces = Object.assign({}, hypr._activeWorkspaces, {
            [screenName]: workspaceId
        });
        if (known)
            hypr.workspaceSwitched(screenName, workspaceId);
    }

    // Quickshell 0.3.2 loses workspaces when refreshToplevels() lands
    // before its own first workspace load (seen: only a placeholder -1
    // left), so a refresh asked for in the first moments waits for it.
    property bool _settled: false
    property bool _refreshPending: false

    function refreshWindows() {
        if (!hypr._settled) {
            hypr._refreshPending = true;
            return;
        }
        Hyprland.refreshMonitors();
        Hyprland.refreshToplevels();
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: {
            hypr._settled = true;
            if (hypr._refreshPending)
                hypr.refreshWindows();
        }
    }

    // { width, height, windows: [{ source, x, y, width, height, z }] } in
    // the monitor's logical pixels, `source` being the Wayland toplevel
    // (for ScreencopyView) and a higher z drawn on top. Geometry comes
    // from the last refreshWindows(); Hyprland reports it in global
    // layout coordinates, so the monitor's position is taken off.
    function workspaceLayout(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        const mon = ws?.monitor ?? null;
        if (!mon || mon.width <= 0 || mon.height <= 0)
            return null;
        const scale = mon.scale > 0 ? mon.scale : 1;
        const turned = (mon.lastIpcObject?.transform ?? 0) % 2 === 1;
        const width = (turned ? mon.height : mon.width) / scale;
        const height = (turned ? mon.width : mon.height) / scale;
        const windows = [];
        for (const t of ws.toplevels.values) {
            const ipc = t.lastIpcObject ?? {};
            if (!t.wayland || !ipc.at || !ipc.size || ipc.hidden)
                continue;
            windows.push({
                source: t.wayland,
                x: ipc.at[0] - mon.x,
                y: ipc.at[1] - mon.y,
                width: ipc.size[0],
                height: ipc.size[1],
                // focusHistoryID 0 is the most recently focused.
                z: -(ipc.focusHistoryID ?? 0)
            });
        }
        return {
            width: width,
            height: height,
            windows: windows
        };
    }

    // [{ x, y, width, height, floating, focused, stack, fullscreen }]
    // for the windows of the screen's active workspace, in the
    // screen's logical pixels; a lower `stack` was focused more
    // recently. Geometry comes from the last refreshWindows().
    function windowFrames(screenName) {
        const mon = Hyprland.monitors.values.find(m => m.name === screenName);
        const ws = mon?.activeWorkspace ?? null;
        if (!ws)
            return [];
        const frames = [];
        for (const t of ws.toplevels.values) {
            const ipc = t.lastIpcObject ?? {};
            if (!ipc.at || !ipc.size || ipc.hidden)
                continue;
            frames.push({
                x: ipc.at[0] - mon.x,
                y: ipc.at[1] - mon.y,
                width: ipc.size[0],
                height: ipc.size[1],
                floating: ipc.floating ?? false,
                focused: (ipc.focusHistoryID ?? -1) === 0,
                stack: ipc.focusHistoryID ?? 0,
                fullscreen: (ipc.fullscreen ?? 0) > 0
            });
        }
        return frames;
    }

    // Wayland app ids, falling back to Hyprland's class until the
    // toplevel's Wayland handle binds.
    function workspaceApps(id) {
        const ws = Hyprland.workspaces.values.find(w => w.id === id);
        if (!ws)
            return [];
        return ws.toplevels.values.map(t => t.wayland?.appId ?? t.lastIpcObject?.class ?? "").filter(a => a.length > 0);
    }

    function _setActiveWorkspaceName(screenName, name) {
        if (!screenName || hypr.activeWorkspaceNames[screenName] === name)
            return;
        hypr.activeWorkspaceNames = Object.assign({}, hypr.activeWorkspaceNames, {
            [screenName]: name
        });
    }

    // Hyprland's Lua config takes Lua for dispatch, not the old
    // "workspace N" dispatcher syntax.
    function switchWorkspace(id) {
        const n = Number(id);
        if (!Number.isInteger(n))
            return;
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + n + " })");
    }

    // Same dispatcher as the Super+Shift+N binding.
    function moveFocusedWindow(id) {
        const n = Number(id);
        if (!Number.isInteger(n))
            return;
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + n + " })");
    }

    function _setWorkspace(id, windows, urgent) {
        if (hypr.workspaceWindows[id] !== windows) {
            const w = Object.assign({}, hypr.workspaceWindows);
            if (windows === undefined)
                delete w[id];
            else
                w[id] = windows;
            hypr.workspaceWindows = w;
        }
        if ((hypr.urgentWorkspaces[id] ?? false) !== urgent) {
            const u = Object.assign({}, hypr.urgentWorkspaces);
            if (urgent)
                u[id] = true;
            else
                delete u[id];
            hypr.urgentWorkspaces = u;
        }
    }

    function _recountFullscreen() {
        const vals = ToplevelManager.toplevels.values;
        let n = 0;
        for (let i = 0; i < vals.length; i++)
            if (vals[i].fullscreen)
                n++;
        hypr._fullscreenCount = n;
    }

    Instantiator {
        model: ToplevelManager.toplevels

        delegate: QtObject {
            required property var modelData

            readonly property bool fs: modelData.fullscreen ?? false

            onFsChanged: hypr._recountFullscreen()
            Component.onCompleted: hypr._recountFullscreen()
            // Deferred: at destruction time the model still lists
            // the departing toplevel.
            Component.onDestruction: Qt.callLater(hypr._recountFullscreen)
        }
    }

    Instantiator {
        model: Hyprland.monitors

        delegate: QtObject {
            required property var modelData
            readonly property string screenName: modelData.name ?? ""
            readonly property int activeWorkspaceId: modelData.activeWorkspace?.id ?? 1
            readonly property string activeWorkspaceName: modelData.activeWorkspace?.name ?? ""

            onActiveWorkspaceIdChanged: hypr._setActiveWorkspace(screenName, activeWorkspaceId)
            onActiveWorkspaceNameChanged: hypr._setActiveWorkspaceName(screenName, activeWorkspaceName)
            Component.onCompleted: {
                hypr._setActiveWorkspace(screenName, activeWorkspaceId);
                hypr._setActiveWorkspaceName(screenName, activeWorkspaceName);
                hypr.monitorsRevision++;
            }
            Component.onDestruction: Qt.callLater(() => hypr.monitorsRevision++)
        }
    }

    Instantiator {
        model: Hyprland.workspaces

        delegate: QtObject {
            required property var modelData
            readonly property int workspaceId: modelData.id
            readonly property int windows: modelData.toplevels.values.length
            readonly property bool urgent: modelData.urgent

            onWindowsChanged: hypr._setWorkspace(workspaceId, windows, urgent)
            onUrgentChanged: hypr._setWorkspace(workspaceId, windows, urgent)
            Component.onCompleted: hypr._setWorkspace(workspaceId, windows, urgent)
            Component.onDestruction: {
                const id = workspaceId;
                // Deferred, and skipped if Hyprland recreated the id.
                Qt.callLater(() => {
                    if (!Hyprland.workspaces.values.some(w => w.id === id))
                        hypr._setWorkspace(id, undefined, false);
                });
            }
        }
    }
}
