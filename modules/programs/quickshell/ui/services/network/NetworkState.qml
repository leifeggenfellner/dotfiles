pragma Singleton
import QtQuick
import "./"

// ── Connection Ritual State Machine ──────────────────────────
// Orchestrates mode/state/device flow.
// External system interactions are delegated to adapters.

Item {
    id: connectionState

    // "wifi" | "ethernet" | "bluetooth"
    property string mode: "wifi"

    // "idle" | "scanning" | "connecting" | "connected" | "error"
    property string status: "idle"

    // Array of { id, name, type, state, signal, secured, paired }
    property var devices: []

    // "wifi" | "ethernet" | "offline" - for glance-level widgets
    readonly property string activeType: {
        for (let i = 0; i < _cacheEthernet.length; i++) {
            if (_cacheEthernet[i].state === "connected")
                return "ethernet";
        }
        if (wifiEnabled && _cacheWifiActiveName.length > 0)
            return "wifi";
        return "offline";
    }

    property string focusedId: ""
    property string errorMessage: ""
    property string errorCode: "none"

    readonly property bool wifiEnabled: wifiAdapter.powerEnabled
    readonly property bool bluetoothEnabled: bluetoothAdapter.powerEnabled

    property string activeConnectionName: ""
    property bool panelOpen: false

    // UI view state — owned here so multiple views stay in sync
    property string wifiSearchQuery: ""
    property bool passwordPanelOpen: false
    property string passwordDraft: ""

    readonly property var filteredDevices: {
        if (mode !== "wifi")
            return devices;
        let q = (wifiSearchQuery || "").trim().toLowerCase();
        if (q.length === 0)
            return devices;
        let out = [];
        for (let i = 0; i < devices.length; i++) {
            if ((devices[i].name || "").toLowerCase().indexOf(q) >= 0)
                out.push(devices[i]);
        }
        return out;
    }

    function openPasswordPrompt() {
        passwordPanelOpen = true;
        passwordDraft = "";
    }

    function closePasswordPrompt() {
        passwordPanelOpen = false;
        passwordDraft = "";
    }

    function submitPassword() {
        if (focusedId === "" || passwordDraft.length === 0)
            return;
        connectWithPassword(focusedId, passwordDraft);
        closePasswordPrompt();
    }

    property string _pendingDeviceId: ""
    property var pendingConnection: null
    property var savedConnections: []
    property var savedConnectionSsids: []

    // Cache
    property var _cacheWifi: []
    property var _cacheEthernet: []
    property var _cacheBluetooth: []
    property string _cacheWifiActiveName: ""
    property string _cacheEthernetActiveName: ""
    property string _cacheBluetoothActiveName: ""
    property double _cacheWifiTs: 0
    property double _cacheEthernetTs: 0
    property double _cacheBluetoothTs: 0
    property int cacheTtlMs: 15000
    property bool backgroundRefresh: true
    property int backgroundRefreshOpenMs: 1000
    property int backgroundRefreshClosedMs: 60000

    Timer {
        interval: connectionState.panelOpen ? connectionState.backgroundRefreshOpenMs : connectionState.backgroundRefreshClosedMs
        repeat: true
        running: connectionState.backgroundRefresh
        triggeredOnStart: true
        onTriggered: {
            if (connectionState.status === "connecting")
                return;

            wifiAdapter.refreshPower();
            bluetoothAdapter.refreshPower();

            if (connectionState.wifiEnabled)
                wifiAdapter.scan();
            ethernetAdapter.scan();
            if (connectionState.bluetoothEnabled)
                bluetoothAdapter.scan();
        }
    }

    NetworkWifi {
        id: wifiAdapter

        onScanCompleted: function (list, activeName) {
            connectionState._cacheWifi = list;
            connectionState._cacheWifiActiveName = activeName || "";
            connectionState._cacheWifiTs = Date.now();

            if (connectionState.mode === "wifi") {
                connectionState.devices = list;
                connectionState.activeConnectionName = activeName || "";
                connectionState.status = "idle";
            }
        }

        onSavedProfilesLoaded: function (connections, ssids) {
            connectionState.savedConnections = connections || [];
            connectionState.savedConnectionSsids = ssids || [];
        }

        onActionCompleted: function (action, ok, code, message) {
            if (action === "connect" || action === "connectWithPassword") {
                if (ok) {
                    connectionState.status = "connected";
                    connectionState.errorCode = "none";
                    connectionState.errorMessage = "";
                    connectionState._setDeviceState(connectionState._pendingDeviceId, "connected");
                    let connected = connectionState._findDevice(connectionState._pendingDeviceId);
                    connectionState.activeConnectionName = connected ? connected.name : connectionState.activeConnectionName;
                } else {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "wifi");
                    connectionState._setDeviceState(connectionState._pendingDeviceId, "error");
                }
                connectionState.pendingConnection = null;
                wifiAdapter.loadSavedConnections();
                wifiAdapter.scan();
                return;
            }

            if (action === "disconnect") {
                if (!ok) {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "wifi");
                    connectionState.pendingConnection = null;
                    return;
                }

                connectionState.status = "idle";
                connectionState.activeConnectionName = "";
                connectionState.pendingConnection = null;
                wifiAdapter.loadSavedConnections();
                connectionState._startScan();
                return;
            }

            if (action === "togglePower") {
                if (!ok) {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "wifi");
                    return;
                }

                connectionState.status = "idle";
                if (connectionState.mode === "wifi") {
                    if (connectionState.wifiEnabled)
                        connectionState._startScan();
                    else
                        connectionState.devices = [];
                }
            }
        }
    }

    NetworkEthernet {
        id: ethernetAdapter

        onScanCompleted: function (list) {
            let activeName = "";
            for (let i = 0; i < list.length; i++) {
                if (list[i].state === "connected") {
                    activeName = list[i].name;
                    break;
                }
            }

            connectionState._cacheEthernet = list;
            connectionState._cacheEthernetActiveName = activeName;
            connectionState._cacheEthernetTs = Date.now();

            if (connectionState.mode === "ethernet") {
                connectionState.devices = list;
                connectionState.status = "idle";
                connectionState.activeConnectionName = activeName;
            }
        }

        onActionCompleted: function (action, ok, code, message) {
            if (action === "disconnect") {
                if (!ok) {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "ethernet");
                    connectionState.pendingConnection = null;
                    return;
                }
                connectionState.status = "idle";
                connectionState.pendingConnection = null;
                connectionState._startScan();
            }
        }
    }

    NetworkBluetooth {
        id: bluetoothAdapter

        onScanCompleted: function (list) {
            let activeName = "";
            for (let i = 0; i < list.length; i++) {
                if (list[i].state === "connected") {
                    activeName = list[i].name;
                    break;
                }
            }

            connectionState._cacheBluetooth = list;
            connectionState._cacheBluetoothActiveName = activeName;
            connectionState._cacheBluetoothTs = Date.now();

            if (connectionState.mode === "bluetooth") {
                connectionState.devices = list;
                connectionState.status = "idle";
                connectionState.activeConnectionName = activeName;
            }
        }

        onActionCompleted: function (action, ok, code, message) {
            if (action === "connect") {
                if (ok) {
                    connectionState.status = "connected";
                    connectionState.errorCode = "none";
                    connectionState.errorMessage = "";
                    connectionState._setDeviceState(connectionState._pendingDeviceId, "connected");
                } else {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "bluetooth");
                    connectionState._setDeviceState(connectionState._pendingDeviceId, "error");
                }
                connectionState.pendingConnection = null;
                bluetoothAdapter.scan();
                return;
            }

            if (action === "disconnect") {
                if (!ok) {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "bluetooth");
                    connectionState.pendingConnection = null;
                    return;
                }
                connectionState.status = "idle";
                connectionState._setDeviceState(connectionState._pendingDeviceId, "idle");
                connectionState.focusedId = "";
                connectionState.pendingConnection = null;
                bluetoothAdapter.scan();
                return;
            }

            if (action === "togglePower") {
                if (!ok) {
                    connectionState.status = "error";
                    connectionState.errorCode = code || "unknown_error";
                    connectionState.errorMessage = connectionState._messageForError(connectionState.errorCode, message, "bluetooth");
                    return;
                }

                connectionState.status = "idle";
                if (connectionState.mode === "bluetooth") {
                    if (connectionState.bluetoothEnabled)
                        connectionState._startScan();
                    else
                        connectionState.devices = [];
                }
            }
        }
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            wifiAdapter.refreshPower();
            bluetoothAdapter.refreshPower();
            connectionState._applyFreshCache(mode);
            _startScan();
        } else {
            focusedId = "";
            errorMessage = "";
            errorCode = "none";
            status = "idle";
            _pendingDeviceId = "";
            pendingConnection = null;
            wifiSearchQuery = "";
            passwordPanelOpen = false;
            passwordDraft = "";
        }
    }

    onModeChanged: {
        if (panelOpen) {
            connectionState._applyFreshCache(mode);
            focusedId = "";
            errorMessage = "";
            errorCode = "none";
            passwordPanelOpen = false;
            passwordDraft = "";
            _startScan();
        }
    }

    function _startScan() {
        status = "scanning";
        if (mode === "wifi") {
            if (!wifiEnabled) {
                devices = [];
                status = "idle";
                return;
            }
            wifiAdapter.scan();
            return;
        }

        if (mode === "bluetooth") {
            if (!bluetoothEnabled) {
                devices = [];
                status = "idle";
                return;
            }
            bluetoothAdapter.scan();
            return;
        }

        ethernetAdapter.scan();
    }

    function connect(deviceId) {
        let device = _findDevice(deviceId);
        if (!device)
            return;

        focusedId = deviceId;
        status = "connecting";
        _pendingDeviceId = deviceId;
        pendingConnection = {
            action: "connect",
            mode: device.type,
            id: device.id,
            name: device.name,
            startedAt: Date.now(),
            requiresPassword: false
        };
        _setDeviceState(deviceId, "connecting");

        if (device.type === "wifi") {
            wifiAdapter.connect(device.name);
        } else if (device.type === "bluetooth") {
            bluetoothAdapter.connect(device.id);
        }
    }

    function connectWithPassword(deviceId, password) {
        let device = _findDevice(deviceId);
        if (!device || device.type !== "wifi")
            return;

        focusedId = deviceId;
        status = "connecting";
        _pendingDeviceId = deviceId;
        pendingConnection = {
            action: "connectWithPassword",
            mode: "wifi",
            id: device.id,
            name: device.name,
            startedAt: Date.now(),
            requiresPassword: true
        };
        _setDeviceState(deviceId, "connecting");

        wifiAdapter.connectWithPassword(device.name, password);
    }

    function disconnect(deviceId) {
        let device = _findDevice(deviceId);
        if (!device)
            return;

        _pendingDeviceId = deviceId;
        pendingConnection = {
            action: "disconnect",
            mode: device.type,
            id: device.id,
            name: device.name,
            startedAt: Date.now(),
            requiresPassword: false
        };

        if (device.type === "wifi") {
            let devId = device.deviceId ? device.deviceId : device.id;
            wifiAdapter.disconnect(devId);
        } else if (device.type === "ethernet") {
            ethernetAdapter.disconnect(device.id);
        } else if (device.type === "bluetooth") {
            bluetoothAdapter.disconnect(device.id);
        }
    }

    function toggleWifi() {
        wifiAdapter.togglePower(wifiEnabled);
    }

    function toggleBluetooth() {
        bluetoothAdapter.togglePower(bluetoothEnabled);
    }

    function retry() {
        errorMessage = "";
        errorCode = "none";
        _startScan();
    }

    function _isCacheFresh(ts) {
        return ts > 0 && (Date.now() - ts) <= cacheTtlMs;
    }

    function _applyFreshCache(targetMode) {
        if (targetMode === "wifi" && _isCacheFresh(_cacheWifiTs)) {
            devices = _cacheWifi;
            activeConnectionName = _cacheWifiActiveName;
            return true;
        }
        if (targetMode === "ethernet" && _isCacheFresh(_cacheEthernetTs)) {
            devices = _cacheEthernet;
            activeConnectionName = _cacheEthernetActiveName;
            return true;
        }
        if (targetMode === "bluetooth" && _isCacheFresh(_cacheBluetoothTs)) {
            devices = _cacheBluetooth;
            activeConnectionName = _cacheBluetoothActiveName;
            return true;
        }
        return false;
    }

    function _messageForError(code, fallback, domain) {
        switch (code) {
        case "auth_failed":
            return domain === "bluetooth" ? "Pairing authentication failed" : "Authentication failed";
        case "timeout":
            return "Request timed out";
        case "unavailable":
            return domain === "bluetooth" ? "Bluetooth unavailable" : "Network unavailable";
        case "radio_off":
            return domain === "bluetooth" ? "Bluetooth is turned off" : "WiFi radio is turned off";
        case "busy":
            return "System is busy, try again";
        default:
            return fallback || "Connection failed";
        }
    }

    function _findDevice(id) {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].id === id)
                return devices[i];
        }
        return null;
    }

    function _setDeviceState(id, newState) {
        let list = devices.slice();
        for (let i = 0; i < list.length; i++) {
            if (list[i].id === id) {
                list[i] = Object.assign({}, list[i], {
                    state: newState
                });
            }
        }
        devices = list;
    }

    Component.onCompleted: {
        wifiAdapter.refreshPower();
        bluetoothAdapter.refreshPower();
        wifiAdapter.loadSavedConnections();
    }
}
