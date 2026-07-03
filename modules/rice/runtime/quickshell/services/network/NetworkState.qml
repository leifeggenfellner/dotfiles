pragma Singleton
import QtQuick
import Quickshell.Io

// ── NetworkState — REAL ───────────────────────────────────────
// NetworkManager via nmcli. Quickshell has no native NM module and
// QML has no direct DBus, so this is D-008 tier 3: EVENT-TRIGGERED
// commands driven by a long-lived `nmcli monitor` stream. The only
// timer is a 400ms debounce coalescing monitor bursts — no polling.
//
//   state:    available, busy, error, mock, connected, activeType,
//             activeDevice, ssid, strength [0..1],
//             networks[] {ssid, strength, secured, active},
//             passwordNeededFor (ssid whose connect wants secrets)
//   commands: connect(ssid, password?), disconnect(), rescan(),
//             clearError()

Item {
    id: network

    readonly property bool mock: false
    property bool available: true
    property bool busy: false
    property string error: ""

    property bool connected: false
    property string activeType: ""
    property string activeDevice: ""
    property string ssid: ""
    property real strength: 0
    property var networks: []
    property string passwordNeededFor: ""
    property string _pendingSsid: ""

    // ── commands ──────────────────────────────────────────────
    function connect(target, password) {
        if (busy)
            return;
        busy = true;
        error = "";
        passwordNeededFor = "";
        _pendingSsid = target;
        _action.command = (password && password.length > 0)
            ? ["nmcli", "device", "wifi", "connect", target, "password", password]
            : ["nmcli", "device", "wifi", "connect", target];
        _action.running = true;
    }

    function clearError() {
        error = "";
        passwordNeededFor = "";
    }

    function disconnect() {
        if (busy || activeDevice.length === 0)
            return;
        busy = true;
        error = "";
        _action.command = ["nmcli", "device", "disconnect", activeDevice];
        _action.running = true;
    }

    function rescan() {
        _wifi.rescanMode = "yes";
        _refresh();
    }

    // ── nmcli output helpers (-t --escape yes: fields ':'-split,
    //    literal ':' and '\' escaped with '\') ─────────────────
    function _splitFields(line) {
        const fields = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const ch = line[i];
            if (ch === "\\" && i + 1 < line.length) {
                cur += line[i + 1];
                i++;
            } else if (ch === ":") {
                fields.push(cur);
                cur = "";
            } else {
                cur += ch;
            }
        }
        fields.push(cur);
        return fields;
    }

    function _refresh() {
        _status.running = true;
    }

    // ── device status (which connection is active) ────────────
    Process {
        id: _status
        command: ["nmcli", "-t", "--escape", "yes", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                let found = null;
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const f = network._splitFields(line);
                    if (f.length < 4)
                        continue;
                    const [dev, type, state, conn] = f;
                    if (state === "connected" && (type === "wifi" || type === "ethernet")) {
                        found = { dev, type, conn };
                        if (type === "wifi")
                            break; // prefer wifi row for ssid/strength detail
                    }
                }
                if (found) {
                    network.connected = true;
                    network.activeType = found.type;
                    network.activeDevice = found.dev;
                    if (found.type === "wifi") {
                        _wifi.running = true;
                    } else {
                        network.ssid = found.conn;
                        network.strength = 1;
                    }
                } else {
                    network.connected = false;
                    network.activeType = "";
                    network.activeDevice = "";
                    network.ssid = "";
                    network.strength = 0;
                }
            }
        }
        onExited: (code, status) => {
            // 127 = nmcli missing, 8 = NetworkManager not running
            network.available = (code === 0);
        }
    }

    // ── wifi list (active ssid/strength + candidates) ─────────
    Process {
        id: _wifi
        property string rescanMode: "no"
        command: ["nmcli", "-t", "--escape", "yes", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "device", "wifi", "list", "--rescan", rescanMode]
        stdout: StdioCollector {
            onStreamFinished: {
                _wifi.rescanMode = "no";
                const seen = {};
                const list = [];
                for (const line of text.split("\n")) {
                    if (line.length === 0)
                        continue;
                    const f = network._splitFields(line);
                    if (f.length < 4)
                        continue;
                    const active = f[0] === "*";
                    const name = f[1];
                    const sig = Math.max(0, Math.min(1, parseInt(f[2], 10) / 100 || 0));
                    const secured = f[3].length > 0 && f[3] !== "--";
                    if (name.length === 0)
                        continue;
                    if (active) {
                        network.ssid = name;
                        network.strength = sig;
                    }
                    const prev = seen[name];
                    if (prev === undefined) {
                        seen[name] = list.length;
                        list.push({ ssid: name, strength: sig, secured, active });
                    } else if (sig > list[prev].strength || active) {
                        list[prev] = { ssid: name, strength: Math.max(sig, list[prev].strength), secured, active: active || list[prev].active };
                    }
                }
                list.sort((a, b) => (b.active - a.active) || (b.strength - a.strength));
                network.networks = list;
            }
        }
    }

    // ── connect/disconnect runner ─────────────────────────────
    Process {
        id: _action
        stderr: StdioCollector {
            id: _actionErr
        }
        onExited: (code, status) => {
            network.busy = false;
            if (code !== 0) {
                const raw = _actionErr.text.trim();
                if (/[Ss]ecrets were required/.test(raw)) {
                    // Semantic state, not prose: UI offers a password prompt.
                    network.passwordNeededFor = network._pendingSsid;
                } else {
                    // One line, not the nmcli essay.
                    const errLine = raw.split("\n").find(l => l.startsWith("Error:"));
                    network.error = (errLine ?? raw.split("\n")[0] ?? "").replace(/^Error:\s*/, "")
                        || ("nmcli failed (exit " + code + ")");
                }
            }
            network._refresh();
        }
    }

    // ── event stream: refresh on NetworkManager activity ──────
    Process {
        id: _monitor
        command: ["nmcli", "monitor"]
        running: network.available
        stdout: SplitParser {
            onRead: _debounce.restart()
        }
        onExited: (code, status) => {
            // NM went away (or nmcli missing); state reflects it.
            network.available = false;
        }
    }

    // Debounce: coalesces monitor line bursts into one refresh.
    // Not a poll — it only fires after an actual NM event.
    Timer {
        id: _debounce
        interval: 400
        onTriggered: network._refresh()
    }

    Component.onCompleted: _refresh()
}
