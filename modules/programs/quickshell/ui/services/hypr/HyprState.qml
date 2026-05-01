pragma Singleton
import Quickshell.Hyprland
import QtQuick

Item {
    id: hyprState

    // Active workspace from native Quickshell Hyprland binding
    readonly property int activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    // Active window from Hyprland IPC socket events
    property string activeWindowTitle: ""
    property string activeWindowClass: ""
    property real activityLevel: 0.0
    property real workspacePulse: 0.0

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            hyprState.activityLevel = Math.max(0.0, hyprState.activityLevel - 0.035);
            hyprState.workspacePulse = Math.max(0.0, hyprState.workspacePulse - 0.08);
        }
    }

    // Listen to raw Hyprland socket2 events for window focus changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            let payload = "";
            let name = "";

            if (event && event.name === "activewindow") {
                name = "activewindow";
                payload = event.data || "";
            } else {
                let raw = String(event || "");
                let sep = raw.indexOf(">>");
                if (sep <= 0) {
                    return;
                }
                name = raw.substring(0, sep);
                payload = raw.substring(sep + 2);
            }

            if (event && event.name) {
                name = event.name;
                if (event.data !== undefined)
                    payload = event.data;
            }

            // Workspace-focused events create a short phase pulse.
            if (name === "workspace" || name === "workspacev2" || name === "focusedmon") {
                hyprState.workspacePulse = 1.0;
                hyprState.activityLevel = Math.max(hyprState.activityLevel, 0.8);
            }

            // General compositor activity pulse.
            if (name === "openwindow" || name === "closewindow" || name === "movewindow" || name === "fullscreen") {
                hyprState.activityLevel = Math.max(hyprState.activityLevel, 0.9);
            }

            if (name === "activewindow" && payload.length > 0) {
                let comma = payload.indexOf(",");
                if (comma >= 0) {
                    hyprState.activeWindowClass = payload.substring(0, comma);
                    hyprState.activeWindowTitle = payload.substring(comma + 1);
                } else {
                    hyprState.activeWindowClass = payload;
                    hyprState.activeWindowTitle = "";
                }

                // Short-lived activity signal used for subtle UI modulation.
                hyprState.activityLevel = 1.0;
            }
        }
    }
}
