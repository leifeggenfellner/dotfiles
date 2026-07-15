pragma Singleton
import QtQuick
import Quickshell.Io

// -- BrightnessState -- REAL -----------------------------------
// brightnessctl is the available backend here, so this is D-008
// tier 3: commands refresh state only after brightnessctl reports
// the real device value.
//
//   state:    available, busy, error, mock, value [0..1], percent
//   commands: refresh(), setValue(v), step(delta)

Item {
    id: brightness

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property bool refreshQueued: false
    property string error: ""

    property real value: 0
    readonly property int percent: Math.round(value * 100)
    property real current: 0
    property real maximum: 0

    function refresh() {
        if (probe.running) {
            refreshQueued = true;
        } else {
            probe.running = true;
        }
    }

    function setValue(v) {
        const clamped = Math.max(0, Math.min(1, v));
        if (_run(["brightnessctl", "set", Math.round(clamped * 100) + "%"]))
            value = clamped;
    }

    function step(delta) {
        const amount = Math.max(1, Math.round(Math.abs(delta) * 100)) + "%";
        if (_run(delta >= 0 ? ["brightnessctl", "set", "+" + amount] : ["brightnessctl", "set", amount + "-"]))
            value = Math.max(0, Math.min(1, value + delta));
    }

    function _run(command) {
        if (action.running) {
            refreshQueued = true;
            return false;
        }
        busy = true;
        error = "";
        action.command = command;
        action.running = true;
        return true;
    }

    function _parse(text) {
        const line = text.trim().split("\n")[0] ?? "";
        const fields = line.split(",");
        if (fields.length < 5) {
            available = false;
            return;
        }

        const percentIndex = String(fields[3]).indexOf("%") >= 0 ? 3 : 4;
        const maximumIndex = percentIndex === 3 ? 4 : 3;
        const rawCurrent = Number(fields[2]);
        const rawMaximum = Number(fields[maximumIndex]);
        const rawPercent = Number(String(fields[percentIndex]).replace("%", ""));
        current = Number.isFinite(rawCurrent) ? rawCurrent : 0;
        maximum = Number.isFinite(rawMaximum) ? rawMaximum : 0;
        value = Number.isFinite(rawPercent) ? Math.max(0, Math.min(1, rawPercent / 100)) : (maximum > 0 ? Math.max(0, Math.min(1, current / maximum)) : 0);
        available = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: probe
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            id: probeOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: probeErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            if (code !== 0) {
                brightness.available = false;
                brightness.error = code === 127 ? "brightnessctl missing" : "brightness probe failed (exit " + code + ")";
                return;
            }
            brightness.error = "";
            brightness._parse(probeOut.text);
            if (brightness.refreshQueued) {
                brightness.refreshQueued = false;
                brightness.refresh();
            }
        }
    }

    Process {
        id: action
        stderr: StdioCollector {
            id: actionErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            brightness.busy = false;
            if (code !== 0) {
                brightness.available = false;
                brightness.error = (actionErr.text.trim().split("\n")[0] ?? "") || "brightnessctl failed (exit " + code + ")";
                return;
            }
            brightness.error = "";
            brightness.refresh();
        }
    }
}
