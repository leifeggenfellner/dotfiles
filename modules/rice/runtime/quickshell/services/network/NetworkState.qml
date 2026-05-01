pragma Singleton
import QtQuick

// ── NetworkState — MOCK, replaced in Phase 5 ──────────────────
// Shape per contracts/service-contract.md:
//   state:    available, busy, error, connected, activeType,
//             ssid, strength [0..1], networks[]
//   commands: connect(ssid), disconnect()

Item {
    id: network

    readonly property bool available: true
    property bool busy: false
    property string error: ""

    property bool connected: true
    property string activeType: "wifi"
    property string ssid: "Aetherwave"
    property real strength: 0.72

    property var networks: [
        { ssid: "Aetherwave", strength: 0.72, secured: true },
        { ssid: "Backroom-5G", strength: 0.55, secured: true },
        { ssid: "CafeGuest", strength: 0.31, secured: false }
    ]

    function connect(target) {
        busy = true;
        ssid = target;
        connected = true;
        busy = false;
    }
    function disconnect() {
        connected = false;
        ssid = "";
        strength = 0;
    }
}
