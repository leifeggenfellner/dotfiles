pragma Singleton
import QtQuick
import Quickshell.Bluetooth

// ── BluetoothState — REAL ─────────────────────────────────────
// Native BlueZ binding via Quickshell.Bluetooth (D-008 tier 1):
// no bluetoothctl, no polling. Devices are the live BluetoothDevice
// objects (name, address, connected, paired, batteryAvailable,
// battery) — property reads stay reactive.
//
//   state:    available, busy, error, mock, powered, devices[]
//   commands: setPowered(on), connect(address), disconnect(address)

Item {
    id: bluetooth

    readonly property bool mock: false
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool busy: false
    property string error: ""

    readonly property bool powered: available ? adapter.enabled : false
    readonly property var devices: {
        if (!available || !adapter.devices)
            return [];
        return adapter.devices.values.filter(d => d.paired || d.connected);
    }

    function setPowered(on) {
        if (available)
            adapter.enabled = on;
    }

    function _find(address) {
        if (!available)
            return null;
        return adapter.devices.values.find(d => d.address === address) ?? null;
    }

    function connect(address) {
        const d = _find(address);
        if (d)
            d.connect();
        else
            error = "no such device: " + address;
    }

    function disconnect(address) {
        const d = _find(address);
        if (d)
            d.disconnect();
    }
}
