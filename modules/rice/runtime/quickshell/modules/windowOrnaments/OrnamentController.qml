import QtQuick
import Quickshell.Hyprland
import "../../core"
import "../../services/hypr"

// ── OrnamentController ────────────────────────────────────────
// Keeps window geometry fresh for the window ornaments (D-074). Off
// unless the theme sets widgets.ornaments.settings.
//
// Hyprland pushes no geometry, so after any event that moves windows
// it raises ShellState.windowsSettling (the ornaments fade out), waits
// for the window animation to finish, re-reads geometry and lowers it
// again: the ornaments come back where the windows came to rest instead
// of jumping ahead of them. Drag-moves and resizes raise no event; a
// slow re-read catches them.

Item {
    id: controller

    readonly property bool enabled: (Theme.widgetConfig("ornaments").settings ?? null) !== null
    // Long enough for the theme's window motion to land.
    readonly property int settleMs: Motion.enabled ? 450 : 60
    readonly property var moving: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2", "focusedmonv2", "moveworkspacev2", "togglegroup", "moveintogroup", "moveoutofgroup", "activespecial", "monitoraddedv2", "monitorremovedv2"]

    onEnabledChanged: {
        ShellState.windowsSettling = false;
        if (enabled)
            HyprState.refreshWindows();
    }
    Component.onCompleted: if (enabled)
        HyprState.refreshWindows()

    Connections {
        target: controller.enabled ? Hyprland : null
        function onRawEvent(event) {
            if (controller.moving.includes(event.name)) {
                ShellState.windowsSettling = true;
                settle.restart();
            } else if (event.name === "activewindowv2") {
                HyprState.refreshWindows();
            }
        }
    }

    Timer {
        id: settle
        interval: controller.settleMs
        onTriggered: {
            HyprState.refreshWindows();
            reveal.restart();
        }
    }

    // The re-read lands asynchronously; give it a beat before showing.
    Timer {
        id: reveal
        interval: 60
        onTriggered: ShellState.windowsSettling = false
    }

    Timer {
        interval: 1000
        repeat: true
        running: controller.enabled && !ShellState.windowsSettling
        onTriggered: HyprState.refreshWindows()
    }
}
