import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
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
//
// When the rice_ornaments Hyprland plugin is loaded (D-080) the
// compositor draws the ornaments itself, frame by frame, and this
// overlay stands down. It asks `hyprctl -j plugin list` at start and
// after every config reload (the plugin loads with the config).

Item {
    id: controller

    readonly property bool themed: (Theme.widgetConfig("ornaments").settings ?? null) !== null
    property bool pluginLoaded: false
    readonly property bool enabled: themed && !pluginLoaded
    // Long enough for the theme's window motion to land.
    readonly property int settleMs: Motion.enabled ? 450 : 60
    readonly property var moving: ["openwindow", "closewindow", "movewindowv2", "changefloatingmode", "fullscreen", "workspacev2", "focusedmonv2", "moveworkspacev2", "togglegroup", "moveintogroup", "moveoutofgroup", "activespecial", "monitoraddedv2", "monitorremovedv2"]

    onEnabledChanged: {
        ShellState.windowsSettling = false;
        if (enabled)
            HyprState.refreshWindows();
    }
    Component.onCompleted: {
        pluginProbe.running = true;
        if (enabled)
            HyprState.refreshWindows();
    }

    Process {
        id: pluginProbe
        command: ["hyprctl", "-j", "plugin", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let loaded = false;
                try {
                    const plugins = JSON.parse(text);
                    loaded = Array.isArray(plugins) && plugins.some(p => p.name === "rice_ornaments");
                } catch (e) {
                    // "no plugins loaded" is plain text.
                }
                controller.pluginLoaded = loaded;
            }
        }
    }

    Connections {
        target: controller.themed ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                pluginProbe.running = true;
                return;
            }
            if (!controller.enabled)
                return;
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
