pragma Singleton
import QtQuick
import QtQml
import Quickshell.Networking

// ── NetworkState — REAL ───────────────────────────────────────
// NetworkManager via Quickshell.Networking (D-008 tier 1): no nmcli,
// no polling. Networks are the live WifiNetwork objects, so a row
// reading name, signalStrength, security, known, connected, state or
// stateChanging stays reactive on its own.
//
//   state:    available, busy, error, mock, connected, activeType
//             ("wifi" | "ethernet" | ""), activeDevice, ssid,
//             strength [0..1], connectivity ("full" | "limited" |
//             "portal" | "none" | "unknown"), wifiAvailable,
//             wifiEnabled, scanning, wiredPresent, wiredConnected,
//             wiredName, wiredSpeed (Mb/s),
//             networks[] (live WifiNetwork; connected, then known,
//             then by signal), failures { name: reason } where
//             reason is "secrets" | "auth" | "timeout" | "lost" |
//             "dropped" | "unknown", passwordNeededFor (a name)
//   commands: connect(name), connectWithPassword(name, password),
//             disconnect(name?), forget(name), setWifiEnabled(on),
//             setScanning(on), rescan(), cancelPassword(), clearError()
//   helpers:  level(network) [0..1], isSecured(network),
//             needsPassword(network)

Item {
    id: network

    readonly property bool mock: false
    readonly property bool available: Networking.backend !== NetworkBackendType.None
    property string error: ""

    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDevice: devices.find(d => d.type === DeviceType.Wired && d.connected) ?? devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiAvailable: wifiDevice !== null && Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool scanning: wifiDevice !== null && wifiDevice.scannerEnabled

    readonly property var networks: {
        if (!wifiDevice || !wifiEnabled)
            return [];
        const seen = {};
        return wifiDevice.networks.values.filter(n => {
            if (n.name.length === 0 || seen[n.name])
                return false;
            seen[n.name] = true;
            return true;
        }).sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (level(b) - level(a)));
    }
    readonly property var activeWifi: networks.find(n => n.connected) ?? null

    readonly property bool wiredPresent: wiredDevice !== null && (wiredDevice.hasLink ?? false)
    readonly property bool wiredConnected: wiredDevice !== null && wiredDevice.connected
    readonly property string wiredName: wiredDevice ? wiredDevice.name : ""
    readonly property int wiredSpeed: wiredDevice ? (wiredDevice.linkSpeed ?? 0) : 0

    readonly property bool connected: activeWifi !== null || wiredConnected
    readonly property string activeType: activeWifi !== null ? "wifi" : (wiredConnected ? "ethernet" : "")
    readonly property string activeDevice: activeWifi !== null ? wifiDevice.name : (wiredConnected ? wiredDevice.name : "")
    readonly property string ssid: activeWifi !== null ? activeWifi.name : (wiredConnected ? wiredDevice.name : "")
    readonly property real strength: activeWifi !== null ? level(activeWifi) : (wiredConnected ? 1 : 0)
    readonly property bool busy: networks.some(n => n.stateChanging)

    readonly property string connectivity: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "full";
        case NetworkConnectivity.Limited:
            return "limited";
        case NetworkConnectivity.Portal:
            return "portal";
        case NetworkConnectivity.None:
            return "none";
        default:
            return "unknown";
        }
    }

    property var failures: ({})
    property string passwordNeededFor: ""

    // ── helpers ───────────────────────────────────────────────
    function level(n) {
        const s = n ? n.signalStrength : 0;
        return Math.max(0, Math.min(1, s > 1 ? s / 100 : s));
    }
    function isSecured(n) {
        return n !== null && n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
    }
    function needsPassword(n) {
        return isSecured(n) && !n.known;
    }

    function _find(name) {
        return networks.find(n => n.name === name) ?? null;
    }
    function _setFailure(name, reason) {
        const next = Object.assign({}, failures);
        if (reason === null)
            delete next[name];
        else
            next[name] = reason;
        failures = next;
    }

    // ── commands ──────────────────────────────────────────────
    function connect(name) {
        const n = _find(name);
        if (!n) {
            error = "not in range: " + name;
            return;
        }
        error = "";
        _setFailure(name, null);
        if (needsPassword(n)) {
            passwordNeededFor = name;
            return;
        }
        passwordNeededFor = "";
        n.connect();
    }

    function connectWithPassword(name, password) {
        const n = _find(name);
        if (!n || !password || password.length === 0)
            return;
        error = "";
        _setFailure(name, null);
        passwordNeededFor = "";
        n.connectWithPsk(password);
    }

    function disconnect(name) {
        if (name) {
            const n = _find(name);
            if (n)
                n.disconnect();
        } else if (activeWifi) {
            activeWifi.disconnect();
        } else if (wiredConnected) {
            wiredDevice.disconnect();
        }
    }

    function forget(name) {
        const n = _find(name);
        if (n)
            n.forget();
        _setFailure(name, null);
    }

    function setWifiEnabled(on) {
        Networking.wifiEnabled = on;
    }

    // The scanner costs power; a page turns it on while it is open.
    function setScanning(on) {
        if (wifiDevice)
            wifiDevice.scannerEnabled = on;
    }
    function rescan() {
        setScanning(true);
    }

    function cancelPassword() {
        if (passwordNeededFor.length > 0)
            _setFailure(passwordNeededFor, null);
        passwordNeededFor = "";
    }

    function clearError() {
        error = "";
        passwordNeededFor = "";
        failures = {};
    }

    // A failed attempt reports why. Missing secrets (no password yet,
    // or a wrong one) asks for the password again.
    Instantiator {
        model: network.networks
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                const why = {
                    [ConnectionFailReason.NoSecrets]: "secrets",
                    [ConnectionFailReason.WifiClientFailed]: "auth",
                    [ConnectionFailReason.WifiAuthTimeout]: "timeout",
                    [ConnectionFailReason.WifiNetworkLost]: "lost",
                    [ConnectionFailReason.WifiClientDisconnected]: "dropped"
                }[reason] ?? "unknown";
                network._setFailure(modelData.name, why);
                if (why === "secrets" && network.isSecured(modelData))
                    network.passwordNeededFor = modelData.name;
            }
        }
    }
}
