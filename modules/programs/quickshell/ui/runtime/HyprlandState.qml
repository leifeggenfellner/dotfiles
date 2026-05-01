pragma Singleton
import Quickshell.Hyprland
import QtQuick

QtObject {
    id: hyprState

    // Active workspace from native Quickshell Hyprland binding
    readonly property int activeWorkspace: Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1

    // Active window from Hyprland IPC socket events
    property string activeWindowTitle: ""
    property string activeWindowClass: ""

    // Listen to raw Hyprland socket2 events for window focus changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.startsWith("activewindow>>")) {
                let payload = event.substring("activewindow>>".length);
                let comma = payload.indexOf(",");
                if (comma >= 0) {
                    hyprState.activeWindowClass = payload.substring(0, comma);
                    hyprState.activeWindowTitle = payload.substring(comma + 1);
                } else {
                    hyprState.activeWindowClass = payload;
                    hyprState.activeWindowTitle = "";
                }
            }
        }
    }
}
