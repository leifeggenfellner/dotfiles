import QtQuick
import "../.."

Item {
    id: field

    property string fieldMode: "field"
    property string focusedId: ""
    property var devices: []
    property color pathwayColor: Theme.accent

    property string mode: "wifi"
    property string activeConnectionName: ""
    property bool wifiEnabled: true

    signal deviceFocused(string deviceId)
    signal deviceUnfocused

    property real orbitPhase: 0.0
    readonly property real centerX: width / 2
    readonly property real centerY: height / 2
    readonly property real orbitRadius: Math.min(width, height) * 0.34
    readonly property real orbitYScale: 1.0
    readonly property int orbitTickMs: 16
    readonly property int orbitLoopMs: 30000
    readonly property real orbitStep: (Math.PI * 2) * (orbitTickMs / orbitLoopMs)
    readonly property int motionDuration: Math.max(90, Math.round(Theme.animDuration * 0.58))
    readonly property int fadeDuration: Math.max(70, Math.round(Theme.animDurationFast * 0.75))

    property int maxOrbitNodes: 8

    property var _orbitSlotById: ({})

    readonly property var focusedDevice: {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].id === focusedId)
                return devices[i];
        }
        return null;
    }
    readonly property var connectedDevice: {
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].state === "connected")
                return devices[i];
        }
        return null;
    }
    readonly property var coreDevice: (focusedDevice && connectedDevice && focusedDevice.id !== connectedDevice.id) ? focusedDevice : connectedDevice

    readonly property var orbitDevices: {
        let out = [];
        let focusedKey = focusedDevice ? focusedDevice.id : "";
        for (let i = 0; i < devices.length; i++) {
            let d = devices[i];
            if (d.id === focusedKey)
                continue;
            if (d.state === "connected" && !(focusedDevice && focusedDevice.id !== d.id))
                continue;
            out.push(d);
        }
        out.sort((a, b) => Number(b.signal || 0) - Number(a.signal || 0));
        return out.slice(0, maxOrbitNodes);
    }
    readonly property real connectedSignal: coreDevice ? Number(coreDevice.signal || 0.0) : 0.0

    function _wifiSignalIcon(sig) {
        if (sig >= 0.80)
            return "󰤨";
        if (sig >= 0.60)
            return "󰤥";
        if (sig >= 0.40)
            return "󰤢";
        if (sig >= 0.20)
            return "󰤟";
        return "󰤯";
    }

    readonly property string coreIcon: {
        if (mode === "bluetooth")
            return coreDevice ? "󰂱" : "󰂯";
        if (mode === "ethernet")
            return coreDevice ? "󰈁" : "󰈀";
        if (!wifiEnabled)
            return "󰤭";
        return _wifiSignalIcon(connectedSignal);
    }
    readonly property string coreLabel: {
        if (coreDevice && coreDevice.name)
            return coreDevice.name;
        if (activeConnectionName && activeConnectionName.length > 0)
            return activeConnectionName;
        if (mode === "wifi")
            return "No WiFi Connected";
        if (mode === "bluetooth")
            return "No Device Connected";
        return "No Ethernet Link";
    }

    onDevicesChanged: _rebuildOrbitSlots()
    onFocusedIdChanged: _rebuildOrbitSlots()

    function _rebuildOrbitSlots() {
        let ids = [];
        for (let i = 0; i < orbitDevices.length; i++)
            ids.push(String(orbitDevices[i].id));
        ids.sort();
        let slots = ({});
        let n = Math.max(1, ids.length);
        for (let j = 0; j < ids.length; j++)
            slots[ids[j]] = (j / n) * Math.PI * 2;
        _orbitSlotById = slots;
    }

    function _baseAngleFor(id) {
        let key = String(id);
        if (_orbitSlotById[key] === undefined)
            return 0;
        return _orbitSlotById[key];
    }

    function focusDevice(deviceId) {
        fieldMode = "focus";
        focusedId = deviceId;
        deviceFocused(deviceId);
    }

    function unfocus() {
        fieldMode = "field";
        focusedId = "";
        deviceUnfocused();
    }

    Timer {
        interval: field.orbitTickMs
        running: field.visible
        repeat: true
        onTriggered: field.orbitPhase += field.orbitStep
    }

    RitualOrbitRings {
        anchors.fill: parent
        pathwayColor: field.pathwayColor
        orbitRadius: field.orbitRadius
        yScale: field.orbitYScale
    }

    RitualOrbitCore {
        anchors.centerIn: parent
        pathwayColor: field.pathwayColor
        iconGlyph: field.coreIcon
        labelText: field.coreLabel
    }

    Repeater {
        model: field.orbitDevices
        delegate: RitualOrbitNode {
            required property var modelData
            orbitField: field
            device: modelData
            onClicked: {
                if (!device)
                    return;
                if (field.fieldMode === "focus" && field.focusedId === device.id)
                    field.unfocus();
                else
                    field.focusDevice(device.id);
            }
        }
    }

    Component.onCompleted: _rebuildOrbitSlots()
}
