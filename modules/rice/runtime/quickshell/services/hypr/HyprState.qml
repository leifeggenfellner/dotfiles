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
//             anyFullscreen, monitorsRevision
//   commands: switchWorkspace(id)
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

    function activeWorkspaceForScreen(screenName) {
        return hypr._activeWorkspaces[screenName] ?? Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1;
    }

    function _setActiveWorkspace(screenName, workspaceId) {
        if (!screenName || hypr._activeWorkspaces[screenName] === workspaceId)
            return;
        hypr._activeWorkspaces = Object.assign({}, hypr._activeWorkspaces, {
            [screenName]: workspaceId
        });
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
}
