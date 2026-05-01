import QtQuick
import Quickshell.Io

// NetworkManager WiFi adapter.
// Handles command execution + resilient nmcli output parsing.

Item {
    id: adapter

    signal scanCompleted(var devices, string activeConnectionName)
    signal actionCompleted(string action, bool ok, string code, string message)
    signal powerChanged(bool enabled)
    signal savedProfilesLoaded(var connectionNames, var ssids)

    property string _pendingSsid: ""
    property bool powerEnabled: true
    property bool scanning: _scan.running
    property int maxReturnedDevices: 0 // 0 = no cap
    property var savedConnections: []
    property var savedConnectionSsids: []

    function _normalizedError(raw, fallbackCode, fallbackMessage) {
        let text = (raw || "").toLowerCase();

        if (text.indexOf("secrets were required") >= 0 || text.indexOf("wrong password") >= 0 || text.indexOf("invalid key") >= 0 || text.indexOf("authentication") >= 0 || text.indexOf("bad password") >= 0) {
            return {
                code: "auth_failed",
                message: "Authentication failed"
            };
        }

        if (text.indexOf("timed out") >= 0 || text.indexOf("timeout") >= 0) {
            return {
                code: "timeout",
                message: "Connection timed out"
            };
        }

        if (text.indexOf("no network with ssid") >= 0 || text.indexOf("not found") >= 0 || text.indexOf("not available") >= 0) {
            return {
                code: "unavailable",
                message: "Network unavailable"
            };
        }

        if (text.indexOf("rfkill") >= 0 || text.indexOf("radio") >= 0 || text.indexOf("disabled") >= 0) {
            return {
                code: "radio_off",
                message: "WiFi radio is disabled"
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

    function _safeSignal(raw) {
        let v = Number(raw);
        if (isNaN(v))
            return 0.0;
        return Math.max(0.0, Math.min(1.0, v / 100.0));
    }

    function _normalizeSsid(ssid, bssid, index) {
        let s = (ssid || "").trim();
        if (s.length > 0 && s !== "--")
            return s;
        let tail = (bssid || "").length >= 5 ? bssid.slice(-5) : String(index + 1);
        return "Hidden " + tail;
    }

    function refreshPower() {
        _powerCheck.running = true;
    }

    function scan() {
        _scan.running = true;
    }

    function loadSavedConnections() {
        _savedConnections.running = true;
    }

    function hasSavedProfile(ssid) {
        let name = (ssid || "").trim().toLowerCase();
        if (name.length === 0)
            return false;

        for (let i = 0; i < adapter.savedConnectionSsids.length; i++) {
            if (String(adapter.savedConnectionSsids[i]).trim().toLowerCase() === name)
                return true;
        }
        return false;
    }

    function connect(ssid) {
        _pendingSsid = ssid;
        _connect._connectMessage = "";
        _connect._connectErr = "";
        _connect.command = ["nmcli", "device", "wifi", "connect", ssid];
        _connect.running = true;
    }

    function connectWithPassword(ssid, password) {
        _pendingSsid = ssid;
        _connectPw._connectPwMessage = "";
        _connectPw._connectPwErr = "";
        _connectPw.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        _connectPw.running = true;
    }

    function disconnect(deviceId) {
        _disconnect._disconnectMessage = "";
        _disconnect._disconnectErr = "";
        _disconnect.command = ["nmcli", "device", "disconnect", deviceId];
        _disconnect.running = true;
    }

    function togglePower(enabled) {
        _toggle._toggleErr = "";
        _toggle.command = ["nmcli", "radio", "wifi", enabled ? "off" : "on"];
        _toggle.running = true;
    }

    Process {
        id: _scan
        // Avoid forcing a full WiFi rescan every panel refresh; this is less disruptive
        // on some chipsets while still keeping device data reasonably fresh.
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,BSSID,SECURITY,SIGNAL,DEVICE", "device", "wifi", "list", "--rescan", "auto"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text || "";
                let lines = text.split("\n");
                let list = [];
                let byName = ({});
                let activeName = "";

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    let parts = adapter._splitEscaped(line, 6);
                    if (parts.length < 5)
                        continue;

                    let inUse = (parts[0] || "").trim();
                    let ssid = parts[1] || "";
                    let bssid = (parts[2] || "").trim();
                    let security = (parts[3] || "").trim();
                    let signal = adapter._safeSignal(parts[4]);
                    let iface = (parts[5] || "").trim();
                    let connected = inUse === "*" || inUse.toLowerCase() === "yes";
                    let name = adapter._normalizeSsid(ssid, bssid, i);
                    let secured = security.length > 0 && security !== "--";

                    let entry = {
                        id: bssid.length > 0 ? bssid : name,
                        name: name,
                        type: "wifi",
                        state: connected ? "connected" : "idle",
                        signal: signal,
                        secured: secured,
                        paired: adapter.hasSavedProfile(name),
                        deviceId: iface.length > 0 ? iface : (bssid.length > 0 ? bssid : name)
                    };

                    // Deduplicate by name to avoid crowded AP aliases; keep strongest.
                    if (byName[name] === undefined) {
                        byName[name] = list.length;
                        list.push(entry);
                    } else {
                        let idx = byName[name];
                        if (entry.signal > list[idx].signal || entry.state === "connected")
                            list[idx] = entry;
                    }

                    if (connected)
                        activeName = name;
                }

                list.sort(function (a, b) {
                    if (a.state === "connected" && b.state !== "connected")
                        return -1;
                    if (b.state === "connected" && a.state !== "connected")
                        return 1;
                    return b.signal - a.signal;
                });

                let visible = adapter.maxReturnedDevices > 0 ? list.slice(0, adapter.maxReturnedDevices) : list;
                adapter.scanCompleted(visible, activeName);
            }
        }
    }

    Process {
        id: _savedConnections
        command: ["nmcli", "-t", "--escape", "yes", "-f", "NAME,TYPE", "connection", "show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = (this.text || "").split("\n");
                let names = [];
                let ssids = [];

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    let parts = adapter._splitEscaped(line, 2);
                    if (parts.length < 2)
                        continue;

                    let nm = (parts[0] || "").trim();
                    let tp = (parts[1] || "").trim();
                    if (nm.length === 0)
                        continue;

                    names.push(nm);
                    if (tp === "802-11-wireless")
                        ssids.push(nm);
                }

                adapter.savedConnections = names;
                adapter.savedConnectionSsids = ssids;
                adapter.savedProfilesLoaded(names, ssids);
            }
        }
    }

    Process {
        id: _powerCheck
        command: ["nmcli", "-t", "-f", "WIFI", "radio"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = (this.text || "").toLowerCase();
                let enabled = raw.indexOf("enabled") >= 0;
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
            let err = adapter._normalizedError(_connectErr + "\n" + _connectMessage, "unknown_error", "Connection failed");
            adapter.actionCompleted("connect", false, err.code, err.message);
        }
    }

    Process {
        id: _connectPw
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                adapter._connectPwMessage = (this.text || "").trim();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                adapter._connectPwErr = (this.text || "").trim();
            }
        }
        property string _connectPwMessage: ""
        property string _connectPwErr: ""
        onExited: function (code) {
            let ok = code === 0;
            if (ok) {
                adapter.actionCompleted("connectWithPassword", true, "none", "");
                return;
            }
            let err = adapter._normalizedError(_connectPwErr + "\n" + _connectPwMessage, "unknown_error", "Connection failed");
            adapter.actionCompleted("connectWithPassword", false, err.code, err.message);
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
            let err = adapter._normalizedError(_toggleErr, "unknown_error", "Failed to toggle WiFi");
            adapter.actionCompleted("togglePower", false, err.code, err.message);
        }
    }
}
