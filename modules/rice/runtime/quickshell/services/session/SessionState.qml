pragma Singleton
import QtQuick
import Quickshell.Io

// ── SessionState — REAL ───────────────────────────────────────
// Session/power actions. Fire-and-forget commands (D-008 tier 3:
// these ARE commands, not state to poll). Command set mirrors the
// legacy power menu.
//
//   commands: lock(), logout(), reboot(), poweroff()

Item {
    id: session

    readonly property bool mock: false
    readonly property bool available: true
    property string error: ""

    function lock() {
        _run(["lock-screen"]);
    }
    function logout() {
        // uwsm stops the session units cleanly (same as Super+Shift+Ctrl+Q);
        // `hyprctl dispatch exit` is not valid under the Lua config.
        _run(["uwsm", "stop"]);
    }
    function reboot() {
        _run(["systemctl", "reboot"]);
    }
    function poweroff() {
        _run(["systemctl", "poweroff"]);
    }

    function _run(cmd) {
        error = "";
        proc.command = cmd;
        proc.running = true;
    }

    Process {
        id: proc
        onExited: (code, status) => {
            if (code !== 0)
                session.error = "command failed (exit " + code + ")";
        }
    }
}
