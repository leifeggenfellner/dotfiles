import QtQuick
import Quickshell.Io

// BlueZ adapter backed by bluetoothctl.

Item {
    id: adapter

    signal scanCompleted(var devices)
    signal actionCompleted(string action, bool ok, string code, string message)
    signal powerChanged(bool enabled)

    property var _lastDevices: []
    property bool powerEnabled: true
    property bool scanning: _scanDevices.running || _scanConnected.running

    function _normalizedError(raw, fallbackCode, fallbackMessage) {
        let text = (raw || "").toLowerCase();

        if (text.indexOf("authentication") >= 0 || text.indexOf("not authorized") >= 0) {
            return {
                code: "auth_failed",
                message: "Bluetooth authentication failed"
            };
        }

        if (text.indexOf("timed out") >= 0 || text.indexOf("timeout") >= 0 || text.indexOf("connection attempt failed") >= 0) {
            return {
                code: "timeout",
                message: "Bluetooth connection timed out"
            };
        }

        if (text.indexOf("no default controller") >= 0 || text.indexOf("not available") >= 0 || text.indexOf("no such device") >= 0) {
            return {
                code: "unavailable",
                message: "Bluetooth unavailable"
            };
        }

        if (text.indexOf("powered off") >= 0 || text.indexOf("blocked") >= 0) {
            return {
                code: "radio_off",
                message: "Bluetooth is powered off"
            };
        }

        if (text.indexOf("busy") >= 0) {
            return {
                code: "busy",
                message: "Bluetooth stack is busy"
            };
        }

        return {
            code: fallbackCode,
            message: fallbackMessage
        };
    }

    function refreshPower() {
        _powerCheck.running = true;
    }

    function scan() {
        _scanDevices.running = true;
    }

    function connect(mac) {
        _connect._connectMessage = "";
        _connect._connectErr = "";
        _connect.command = ["bluetoothctl", "connect", mac];
        _connect.running = true;
    }

    function disconnect(mac) {
        _disconnect._disconnectMessage = "";
        _disconnect._disconnectErr = "";
        _disconnect.command = ["bluetoothctl", "disconnect", mac];
        _disconnect.running = true;
    }

    function togglePower(enabled) {
        _toggle._toggleErr = "";
        _toggle.command = ["bluetoothctl", "power", enabled ? "off" : "on"];
        _toggle.running = true;
    }

    Process {
        id: _scanDevices
        command: ["bluetoothctl", "devices"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = (this.text || "").split("\n");
                let parsed = [];
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    let match = line.match(/^Device\s+([0-9A-Fa-f:]{17})\s+(.+)$/);
                    if (!match)
                        continue;

                    parsed.push({
                        id: match[1],
                        name: match[2],
                        type: "bluetooth",
                        state: "idle",
                        signal: 0.5,
                        secured: false,
                        paired: true
                    });
                }

                adapter._lastDevices = parsed;
                _scanConnected.running = true;
            }
        }
    }

    Process {
        id: _scanConnected
        command: ["bluetoothctl", "devices", "Connected"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let connected = [];
                let lines = (this.text || "").split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let m = lines[i].match(/^Device\s+([0-9A-Fa-f:]{17})/);
                    if (m)
                        connected.push(m[1]);
                }

                let list = adapter._lastDevices.slice();
                for (let j = 0; j < list.length; j++) {
                    let isConnected = connected.indexOf(list[j].id) >= 0;
                    list[j] = Object.assign({}, list[j], {
                        state: isConnected ? "connected" : "idle"
                    });
                }

                list.sort(function (a, b) {
                    if (a.state === "connected" && b.state !== "connected")
                        return -1;
                    if (b.state === "connected" && a.state !== "connected")
                        return 1;
                    return a.name.localeCompare(b.name);
                });

                adapter.scanCompleted(list.slice(0, 8));
            }
        }
    }

    Process {
        id: _powerCheck
        command: ["bluetoothctl", "show"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text || "";
                let enabled = text.indexOf("Powered: yes") >= 0;
                adapter.powerEnabled = enabled;
                adapter.powerChanged(enabled);
            }
        }
    }

    Process {
        id: _connect
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                adapter._connectMessage = (this.text || "").trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                adapter._connectErr = (this.text || "").trim();
            }
        }
        property string _connectMessage: ""
        property string _connectErr: ""
        onExited: function (code) {
            let ok = code === 0;
            if (ok) {
                adapter.actionCompleted("connect", true, "none", "");
                return;
            }
            let err = adapter._normalizedError(_connectErr + "\n" + _connectMessage, "unknown_error", "Pairing failed");
            adapter.actionCompleted("connect", false, err.code, err.message);
        }
    }

    Process {
        id: _disconnect
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                adapter._disconnectMessage = (this.text || "").trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                adapter._disconnectErr = (this.text || "").trim();
            }
        }
        property string _disconnectMessage: ""
        property string _disconnectErr: ""
        onExited: function (code) {
            let ok = code === 0;
            if (ok) {
                adapter.actionCompleted("disconnect", true, "none", "");
                return;
            }
            let err = adapter._normalizedError(_disconnectErr + "\n" + _disconnectMessage, "unknown_error", "Disconnect failed");
            adapter.actionCompleted("disconnect", false, err.code, err.message);
        }
    }

    Process {
        id: _toggle
        command: []
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                _toggle._toggleErr = (this.text || "").trim();
            }
        }
        property string _toggleErr: ""
        onExited: function (code) {
            adapter.refreshPower();
            if (code === 0) {
                adapter.actionCompleted("togglePower", true, "none", "");
                return;
            }
            let err = adapter._normalizedError(_toggleErr, "unknown_error", "Failed to toggle Bluetooth");
            adapter.actionCompleted("togglePower", false, err.code, err.message);
        }
    }
}
