import QtQuick
import Quickshell.Io

// NetworkManager Ethernet adapter.

Item {
    id: adapter

    signal scanCompleted(var devices)
    signal actionCompleted(string action, bool ok, string code, string message)

    function _normalizedError(raw, fallbackCode, fallbackMessage) {
        let text = (raw || "").toLowerCase();

        if (text.indexOf("timed out") >= 0 || text.indexOf("timeout") >= 0) {
            return {
                code: "timeout",
                message: "Request timed out"
            };
        }

        if (text.indexOf("not available") >= 0 || text.indexOf("not found") >= 0 || text.indexOf("no such") >= 0) {
            return {
                code: "unavailable",
                message: "Ethernet device unavailable"
            };
        }

        if (text.indexOf("busy") >= 0) {
            return {
                code: "busy",
                message: "Network stack is busy"
            };
        }

        return {
            code: fallbackCode,
            message: fallbackMessage
        };
    }

    function _splitEscaped(line, expectedParts) {
        let parts = [];
        let buf = "";
        let escaping = false;

        for (let i = 0; i < line.length; i++) {
            let ch = line[i];
            if (escaping) {
                buf += ch;
                escaping = false;
                continue;
            }
            if (ch === "\\") {
                escaping = true;
                continue;
            }
            if (ch === ":" && (expectedParts <= 0 || parts.length < expectedParts - 1)) {
                parts.push(buf);
                buf = "";
                continue;
            }
            buf += ch;
        }
        parts.push(buf);
        return parts;
    }

    function scan() {
        _scan.running = true;
    }

    function disconnect(deviceId) {
        _disconnect._disconnectMessage = "";
        _disconnect._disconnectErr = "";
        _disconnect.command = ["nmcli", "device", "disconnect", deviceId];
        _disconnect.running = true;
    }

    Process {
        id: _scan
        command: ["nmcli", "-t", "--escape", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = (this.text || "").split("\n");
                let parsed = [];
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    let parts = adapter._splitEscaped(line, 4);
                    if (parts.length < 4)
                        continue;

                    let dev = (parts[0] || "").trim();
                    let type = (parts[1] || "").trim();
                    let state = (parts[2] || "").trim();
                    let conn = (parts[3] || "").trim();

                    if (type !== "ethernet")
                        continue;

                    parsed.push({
                        id: dev,
                        name: (conn.length > 0 && conn !== "--") ? conn : dev,
                        type: "ethernet",
                        state: state === "connected" ? "connected" : "idle",
                        signal: 1.0,
                        secured: false,
                        paired: false
                    });
                }
                adapter.scanCompleted(parsed);
            }
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
}
