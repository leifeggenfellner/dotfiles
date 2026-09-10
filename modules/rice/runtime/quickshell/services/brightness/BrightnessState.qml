pragma Singleton
import QtQuick
import Quickshell.Io

// -- BrightnessState -- REAL -----------------------------------
// brightnessctl is the available backend here, so this is D-008
// tier 3: commands refresh state only after brightnessctl reports
// the real device value.
//
//   state:    available, busy, error, actionError, probeError, mock,
//             value [0..1], percent, pending, requestedValue [0..1],
//             requestedValueKnown
//   commands: refresh(), setValue(v), step(delta)

Item {
    id: brightness

    readonly property bool mock: false
    property bool available: false
    property bool busy: false
    property bool refreshQueued: false
    property string actionError: ""
    property string probeError: ""
    readonly property string error: actionError !== "" ? actionError : probeError

    property real value: 0
    property real requestedValue: 0
    property bool requestedValueKnown: false
    readonly property bool pending: busy || _awaitingConfirmation || _queuedKind !== ""
    readonly property int percent: Math.round(value * 100)
    property real current: 0
    property real maximum: 0
    property bool _awaitingConfirmation: false
    property bool _confirmationQueued: false
    property bool _failureReconcileQueued: false
    property string _queuedKind: ""
    property real _queuedValue: 0
    property real _queuedDelta: 0

    function refresh() {
        if (action.running || _awaitingConfirmation) {
            refreshQueued = true;
            return;
        }
        if (probe.running)
            refreshQueued = true;
        else
            _startProbe(false);
    }

    function setValue(v) {
        const clamped = Math.max(0, Math.min(1, v));
        requestedValue = clamped;
        requestedValueKnown = true;
        if (action.running || _awaitingConfirmation) {
            _queuedKind = "absolute";
            _queuedValue = clamped;
            _queuedDelta = 0;
            return;
        }
        _startAbsolute(clamped);
    }

    function step(delta) {
        const percentDelta = Math.round(delta * 100);
        if (percentDelta === 0)
            return;

        const normalizedDelta = percentDelta / 100;
        if (requestedValueKnown || available) {
            const base = requestedValueKnown && pending ? requestedValue : value;
            requestedValue = Math.max(0, Math.min(1, base + normalizedDelta));
            requestedValueKnown = true;
        } else {
            requestedValueKnown = false;
        }

        if (action.running || _awaitingConfirmation) {
            if (_queuedKind === "absolute")
                _queuedValue = Math.max(0, Math.min(1, _queuedValue + normalizedDelta));
            else {
                _queuedKind = "relative";
                _queuedDelta += normalizedDelta;
            }
            return;
        }
        _startRelative(normalizedDelta);
    }

    function _beginAction(command) {
        busy = true;
        actionError = "";
        action.command = command;
        action.running = true;
    }

    function _absolutePercent(target) {
        return Math.round(target * 100);
    }

    function _startAbsolute(target) {
        _beginAction(["brightnessctl", "-m", "set", _absolutePercent(target) + "%"]);
    }

    function _startRelative(delta) {
        const amount = Math.min(100, Math.abs(Math.round(delta * 100)));
        _beginAction(["brightnessctl", "-m", "set", amount + "%" + (delta > 0 ? "+" : "-")]);
    }

    function _startProbe(confirmsWrite) {
        probe.confirmsWrite = confirmsWrite;
        probe.running = true;
    }

    function _parse(text) {
        const line = text.trim().split("\n")[0] ?? "";
        const fields = line.split(",");
        if (fields.length < 5) {
            available = false;
            return false;
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
        if (!pending) {
            requestedValue = value;
            requestedValueKnown = true;
        }
        return true;
    }

    function _finishConfirmation() {
        _awaitingConfirmation = false;
        if (_queuedKind === "absolute") {
            const target = _queuedValue;
            _queuedKind = "";
            if (_absolutePercent(target) !== _absolutePercent(value)) {
                _startAbsolute(target);
                return;
            }
        } else if (_queuedKind === "relative") {
            const delta = _queuedDelta;
            _queuedKind = "";
            _queuedDelta = 0;
            if (Math.abs(delta) >= 0.005) {
                _startRelative(delta);
                return;
            }
        }
        busy = false;
        requestedValue = value;
        requestedValueKnown = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: probe
        property bool confirmsWrite: false
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
            const confirmsWrite = probe.confirmsWrite;
            probe.confirmsWrite = false;
            if (code !== 0) {
                brightness.available = false;
                brightness.probeError = code === 127 ? "brightnessctl missing" : "brightness probe failed (exit " + code + ")";
            } else {
                brightness.probeError = "";
                if (!brightness._parse(probeOut.text))
                    brightness.probeError = "brightness probe returned invalid output";
            }

            if (confirmsWrite) {
                if (code === 0 && brightness.available)
                    brightness._finishConfirmation();
                else {
                    brightness.busy = false;
                    brightness._awaitingConfirmation = false;
                    brightness._queuedKind = "";
                    brightness._queuedDelta = 0;
                    brightness.requestedValue = brightness.value;
                    brightness.requestedValueKnown = brightness.available;
                }
            }

            if (brightness._failureReconcileQueued) {
                brightness._failureReconcileQueued = false;
                brightness._startProbe(false);
            } else if (brightness._confirmationQueued) {
                brightness._confirmationQueued = false;
                brightness._startProbe(true);
            } else if (brightness.refreshQueued && !brightness.busy) {
                brightness.refreshQueued = false;
                brightness.refresh();
            }
        }
    }

    Process {
        id: action
        stdout: StdioCollector {
            id: actionOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: actionErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            if (code !== 0) {
                brightness.busy = false;
                brightness.available = code !== 127;
                brightness.actionError = (actionErr.text.trim().split("\n")[0] ?? "") || "brightnessctl failed (exit " + code + ")";
                brightness._awaitingConfirmation = false;
                brightness._confirmationQueued = false;
                brightness._queuedKind = "";
                brightness._queuedDelta = 0;
                brightness.requestedValue = brightness.value;
                brightness.requestedValueKnown = brightness.available;
                if (probe.running)
                    brightness._failureReconcileQueued = true;
                else
                    brightness._startProbe(false);
                return;
            }
            brightness._parse(actionOut.text);
            brightness._awaitingConfirmation = true;
            brightness.refreshQueued = false;
            if (probe.running)
                brightness._confirmationQueued = true;
            else
                brightness._startProbe(true);
        }
    }
}
