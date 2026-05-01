pragma Singleton
import QtQuick

// ── BluetoothState — MOCK, replaced in Phase 5 ────────────────
// Shape per contracts/service-contract.md:
//   state:    available, busy, error, powered, devices[]
//   commands: setPowered(on), connect(address), disconnect(address)

Item {
    id: bluetooth

    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property bool powered: true
    property var devices: [
        { name: "Keyboard", address: "AA:11", connected: true, battery: 0.8 },
        { name: "Headset", address: "BB:22", connected: false, battery: 0.5 }
    ]

    function setPowered(on) {
        powered = on;
    }
    function connect(address) {
        devices = devices.map(d => d.address === address ? Object.assign({}, d, { connected: true }) : d);
    }
    function disconnect(address) {
        devices = devices.map(d => d.address === address ? Object.assign({}, d, { connected: false }) : d);
    }
}
