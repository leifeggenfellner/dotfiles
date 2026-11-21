pragma Singleton
import QtQuick
import QtQml
import Quickshell.Bluetooth

// ── BluetoothState — REAL ─────────────────────────────────────
// Native BlueZ binding via Quickshell.Bluetooth (D-008 tier 1):
// no bluetoothctl, no polling. Devices are the live BluetoothDevice
// objects (name, address, icon, state, connected, paired, pairing,
// batteryAvailable, battery) — property reads stay reactive.
//
// BlueZ reports no failure reasons, so the service remembers what it
// asked for and reports an attempt that ends without the result: a
// pairing that stops unpaired, a connect that falls back to
// disconnected. PIN and passkey prompts belong to the session's BlueZ
// agent (blueman-applet here), not to this service.
//
//   state:    available, busy (adapter switching), error, mock,
//             powered, discovering, devices[] (paired; connected
//             first, then by name), nearby[] (discovered, unpaired,
//             named; by name), failures { address: "pair" |
//             "connect" }
//   commands: setPowered(on), setDiscovering(on), connect(address),
//             disconnect(address), pair(address), cancelPair(address),
//             forget(address), clearError()
//   helpers:  pending(device) (connecting, disconnecting or pairing)

Item {
    id: bluetooth

    readonly property bool mock: false
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool busy: available && (adapter.state === BluetoothAdapterState.Enabling || adapter.state === BluetoothAdapterState.Disabling)
    property string error: ""

    readonly property bool powered: available ? adapter.enabled : false
    readonly property bool discovering: available && adapter.discovering

    readonly property var _all: available && adapter.devices ? adapter.devices.values : []
    readonly property var devices: _all.filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    // BlueZ names an unnamed device after its address; those stay hidden.
    readonly property var nearby: _all.filter(d => !d.paired && !d.connected && d.name.length > 0 && d.name.replace(/-/g, ":").toUpperCase() !== d.address.toUpperCase()).sort((a, b) => a.name.localeCompare(b.name))

    property var failures: ({})
    // address → "pair" | "connect": what was asked and not yet settled.
    property var _asked: ({})

    function pending(d) {
        return d !== null && (d.pairing || d.state === BluetoothDeviceState.Connecting || d.state === BluetoothDeviceState.Disconnecting);
    }

    function _find(address) {
        return _all.find(d => d.address === address) ?? null;
    }
    function _mark(map, address, value) {
        const next = Object.assign({}, map);
        if (value === null)
            delete next[address];
        else
            next[address] = value;
        return next;
    }
    function _ask(address, what) {
        failures = _mark(failures, address, null);
        _asked = _mark(_asked, address, what);
    }
    function _settle(address, failedAs) {
        _asked = _mark(_asked, address, null);
        if (failedAs)
            failures = _mark(failures, address, failedAs);
    }

    // ── commands ──────────────────────────────────────────────
    function setPowered(on) {
        if (available)
            adapter.enabled = on;
    }

    // Discovery costs power; a page turns it on while it is open.
    function setDiscovering(on) {
        if (available && powered && adapter.discovering !== on)
            adapter.discovering = on;
    }

    function connect(address) {
        const d = _find(address);
        if (!d) {
            error = "no such device: " + address;
            return;
        }
        error = "";
        _ask(address, "connect");
        d.connect();
    }

    function disconnect(address) {
        const d = _find(address);
        if (d)
            d.disconnect();
    }

    // Pairs, then trusts the device so it reconnects on its own, then
    // connects (see the watcher below).
    function pair(address) {
        const d = _find(address);
        if (!d)
            return;
        error = "";
        _ask(address, "pair");
        d.pair();
    }

    function cancelPair(address) {
        const d = _find(address);
        if (d && d.pairing)
            d.cancelPair();
        _settle(address, null);
    }

    function forget(address) {
        const d = _find(address);
        if (d)
            d.forget();
        _settle(address, null);
        failures = _mark(failures, address, null);
    }

    function clearError() {
        error = "";
        failures = {};
    }

    Instantiator {
        model: bluetooth._all
        delegate: Connections {
            required property var modelData
            target: modelData

            function onPairingChanged() {
                const d = modelData;
                if (d.pairing || bluetooth._asked[d.address] !== "pair")
                    return;
                if (d.paired) {
                    bluetooth._settle(d.address, null);
                    d.trusted = true;
                    bluetooth.connect(d.address);
                } else {
                    bluetooth._settle(d.address, "pair");
                }
            }

            function onStateChanged() {
                const d = modelData;
                if (bluetooth._asked[d.address] !== "connect")
                    return;
                if (d.state === BluetoothDeviceState.Connected)
                    bluetooth._settle(d.address, null);
                else if (d.state === BluetoothDeviceState.Disconnected)
                    bluetooth._settle(d.address, "connect");
            }
        }
    }
}
