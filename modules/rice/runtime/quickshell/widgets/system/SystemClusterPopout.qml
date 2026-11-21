import QtQuick
import Quickshell
import "../../core"
import "../../components"

// ── SystemClusterPopout ───────────────────────────────────────
// The control centre (docs/design/control-centre.md, D-088, D-089): quick
// toggles and sliders on its home, and drill-in pages for Wi-Fi and
// Bluetooth. Services: network, audio, bluetooth, tray (injected).
// The tray lives on the home unless the theme turns on the tray hatch
// (settings.showTray = false, D-064); menus stay app-native (D-036).
//
// Every state shown is the service's: a row is pending, failed or
// active because the system says so. Rows come from ScriptModel, so a
// rescan updates them in place without losing focus. Pages run their
// scanners (Wi-Fi scan, Bluetooth discovery) only while open.

FocusScope {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var net: services.network ?? null
    readonly property var audio: services.audio ?? null
    readonly property var bt: services.bluetooth ?? null
    readonly property var tray: services.tray ?? null

    width: 360
    implicitHeight: stack.implicitHeight

    Component.onCompleted: root.net?.clearError()

    PageStack {
        id: stack
        width: parent.width
        focus: true
        home: homePage
        pages: ({
                wifi: wifiPage,
                bluetooth: bluetoothPage
            })
    }

    // ↑/↓ walk the focus chain on every page.
    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Up && event.key !== Qt.Key_Down)
            return;
        const window = root.Window.window;
        const current = window ? window.activeFocusItem : null;
        const next = current ? current.nextItemInFocusChain(event.key === Qt.Key_Down) : null;
        if (next) {
            next.forceActiveFocus();
            event.accepted = true;
        }
    }

    function failureText(reason) {
        return ({
                secrets: "Wrong or missing password",
                auth: "Couldn't authenticate",
                timeout: "Timed out",
                lost: "Went out of range",
                dropped: "The network dropped the connection"
            })[reason] ?? "Couldn't connect";
    }

    function deviceIcon(device) {
        const kind = device.icon ?? "";
        if (/head(set|phone)|earbud/.test(kind))
            return "headphones";
        if (/audio-card|speaker/.test(kind))
            return "speaker";
        if (/keyboard/.test(kind))
            return "keyboard";
        if (/mouse|tablet/.test(kind))
            return "mouse";
        if (/phone/.test(kind))
            return "phone";
        if (/gaming|joystick/.test(kind))
            return "gamepad";
        if (/computer/.test(kind))
            return "laptop";
        return "bluetooth";
    }

    component SectionLabel: Text {
        color: Theme.colors.fg.subtle
        font.family: Theme.typography.families.display
        font.pointSize: Theme.typography.sizes.small + 1
    }

    component Note: Row {
        property string text: ""
        property bool working: false
        spacing: Theme.metrics.space.sm
        leftPadding: Theme.metrics.space.sm

        Spinner {
            visible: parent.working
            anchors.verticalCenter: parent.verticalCenter
            size: Theme.typography.sizes.small + 2
        }
        Text {
            text: parent.text
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }

    // ── Home ──────────────────────────────────────────────────
    Component {
        id: homePage

        FocusScope {
            implicitHeight: homeColumn.implicitHeight

            function focusFirst() {
                wifiTile.visible ? wifiTile.forceActiveFocus() : forceActiveFocus();
            }

            Column {
                id: homeColumn
                width: parent.width
                spacing: Theme.metrics.space.md

                Grid {
                    id: tiles
                    width: parent.width
                    columns: 2
                    spacing: Theme.metrics.space.sm

                    readonly property real tileWidth: (width - spacing) / 2

                    ToggleTile {
                        id: wifiTile
                        visible: root.net !== null && root.net.available
                        width: tiles.tileWidth
                        icon: {
                            if (!root.net || !root.net.wifiEnabled)
                                return root.net && root.net.wiredConnected ? "ethernet" : "wifi-off";
                            return root.net.activeType === "ethernet" ? "ethernet" : "wifi";
                        }
                        label: "Wi-Fi"
                        checked: root.net !== null && root.net.wifiEnabled
                        busy: root.net !== null && root.net.busy
                        hasPage: true
                        available: root.net !== null && root.net.wifiAvailable
                        detail: {
                            const n = root.net;
                            if (!n)
                                return "";
                            const joining = n.networks.find(x => x.stateChanging);
                            if (joining)
                                return "Joining " + joining.name + "…";
                            if (n.activeType === "wifi")
                                return n.ssid;
                            if (n.wiredConnected)
                                return "Wired";
                            return n.wifiEnabled ? "Not connected" : "Off";
                        }
                        onToggled: root.net.setWifiEnabled(!root.net.wifiEnabled)
                        onOpened: stack.open("wifi")
                    }

                    ToggleTile {
                        visible: root.bt !== null && root.bt.available
                        width: tiles.tileWidth
                        icon: root.bt && root.bt.powered ? "bluetooth" : "bluetooth-off"
                        label: "Bluetooth"
                        checked: root.bt !== null && root.bt.powered
                        busy: root.bt !== null && root.bt.busy
                        hasPage: true
                        detail: {
                            if (!root.bt || !root.bt.powered)
                                return "Off";
                            const linked = root.bt.devices.filter(d => d.connected);
                            if (linked.length === 0)
                                return "No devices";
                            const first = linked[0];
                            const battery = first.batteryAvailable ? " · " + Math.round(first.battery * 100) + "%" : "";
                            return linked.length > 1 ? linked.length + " devices" : first.name + battery;
                        }
                        onToggled: root.bt.setPowered(!root.bt.powered)
                        onOpened: stack.open("bluetooth")
                    }
                }

                ValueSlider {
                    visible: root.audio !== null && root.audio.available
                    width: parent.width
                    icon: root.audio && root.audio.muted ? "volume-muted" : "volume"
                    value: root.audio ? root.audio.volume : 0
                    muted: root.audio !== null && root.audio.muted
                    onMoved: v => root.audio.setVolume(v)
                    onIconClicked: root.audio.toggleMuted()
                }

                // The tray (L-009; a theme with the tray hatch hides it here).
                Column {
                    visible: (root.settings.showTray ?? true) && root.tray !== null && root.tray.items.length > 0
                    width: parent.width
                    spacing: Theme.metrics.space.xs

                    SectionLabel {
                        text: "Tray"
                    }
                    TrayGrid {
                        width: parent.width
                        tray: root.tray
                    }
                }
            }
        }
    }

    // ── Wi-Fi ─────────────────────────────────────────────────
    Component {
        id: wifiPage

        FocusScope {
            id: page
            implicitHeight: wifiColumn.implicitHeight

            readonly property var net: root.net
            readonly property string asking: net ? net.passwordNeededFor : ""

            // The scanner runs only while this page is open. The service is
            // held from the start: by teardown the injected one may be gone.
            property var heldNet: null
            Component.onCompleted: {
                heldNet = net;
                heldNet?.setScanning(true);
            }
            Component.onDestruction: heldNet?.setScanning(false)

            function focusFirst() {
                if (prompt.visible)
                    prompt.forceActiveFocus();
                else if (list.count > 0)
                    list.itemAt(0)?.forceActiveFocus();
                else
                    forceActiveFocus();
            }

            Column {
                id: wifiColumn
                width: parent.width
                spacing: Theme.metrics.space.sm

                PageHeader {
                    width: parent.width
                    title: "Wi-Fi"
                    hasSwitch: page.net !== null && page.net.wifiAvailable
                    checked: page.net !== null && page.net.wifiEnabled
                    busy: page.net !== null && page.net.busy
                    onBack: stack.back()
                    onToggled: page.net.setWifiEnabled(!page.net.wifiEnabled)
                }

                // Wired, when a cable is in.
                StateRow {
                    visible: page.net !== null && page.net.wiredPresent
                    width: parent.width
                    icon: "ethernet"
                    title: "Wired"
                    subtitle: {
                        if (!page.net || !page.net.wiredConnected)
                            return "Cable in, not connected";
                        return page.net.wiredSpeed > 0 ? page.net.wiredSpeed + " Mb/s" : "Connected";
                    }
                    active: page.net !== null && page.net.wiredConnected
                    actions: page.net && page.net.wiredConnected ? [
                        {
                            id: "disconnect",
                            label: "Disconnect"
                        }
                    ] : []
                    onAction: page.net.disconnect()
                }

                // Joining a secured network: its password, above the list
                // so a rescan never takes the field away.
                Column {
                    visible: page.asking.length > 0
                    width: parent.width
                    spacing: Theme.metrics.space.xs

                    SectionLabel {
                        text: "Join " + page.asking
                    }
                    PasswordPrompt {
                        id: prompt
                        visible: page.asking.length > 0
                        width: parent.width
                        note: page.net && page.net.failures[page.asking] === "secrets" ? "That password didn't work. Try again." : ""
                        onSubmitted: secret => page.net.connectWithPassword(page.asking, secret)
                        onCancelled: {
                            page.net.cancelPassword();
                            page.forceActiveFocus();
                        }
                    }
                }

                Note {
                    visible: page.net !== null && !page.net.wifiEnabled
                    text: page.net && !page.net.wifiAvailable ? "Wi-Fi is switched off in hardware" : "Wi-Fi is off"
                }
                Note {
                    visible: page.net !== null && page.net.wifiEnabled && list.count === 0
                    working: true
                    text: "Looking for networks…"
                }

                Flickable {
                    id: flick
                    visible: list.count > 0
                    width: parent.width
                    height: Math.min(listColumn.implicitHeight, 340)
                    contentHeight: listColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: listColumn
                        width: parent.width
                        spacing: 2

                        Repeater {
                            id: list
                            model: ScriptModel {
                                values: page.net ? page.net.networks : []
                            }

                            StateRow {
                                id: row
                                required property var modelData
                                readonly property var n: modelData
                                readonly property string reason: page.net && page.net.failures[n.name] ? page.net.failures[n.name] : ""

                                width: listColumn.width
                                title: n.name
                                active: n.connected
                                pending: n.stateChanging
                                failure: reason.length > 0 && reason !== "secrets" ? root.failureText(reason) : ""
                                subtitle: {
                                    if (n.stateChanging)
                                        return n.connected ? "Leaving…" : "Joining…";
                                    if (n.connected) {
                                        const c = page.net.connectivity;
                                        if (c === "portal")
                                            return "Connected · sign-in required";
                                        if (c === "limited" || c === "none")
                                            return "Connected · no internet";
                                        return "Connected";
                                    }
                                    return n.known ? "Saved" : "";
                                }
                                actions: {
                                    if (n.connected)
                                        return [
                                            {
                                                id: "disconnect",
                                                label: "Disconnect"
                                            },
                                            {
                                                id: "forget",
                                                label: "Forget",
                                                danger: true
                                            }
                                        ];
                                    if (n.known)
                                        return [
                                            {
                                                id: "forget",
                                                label: "Forget",
                                                danger: true
                                            }
                                        ];
                                    return [];
                                }

                                onClicked: n.connected ? openActions() : page.net.connect(n.name)
                                onAction: id => id === "forget" ? page.net.forget(n.name) : page.net.disconnect(n.name)
                                onActiveFocusChanged: if (activeFocus) {
                                    const top = row.y;
                                    const bottom = row.y + row.height;
                                    if (top < flick.contentY)
                                        flick.contentY = top;
                                    else if (bottom > flick.contentY + flick.height)
                                        flick.contentY = bottom - flick.height;
                                }

                                Icon {
                                    visible: page.net !== null && page.net.isSecured(row.n)
                                    anchors.verticalCenter: parent.verticalCenter
                                    name: "lock"
                                    size: Theme.typography.sizes.small
                                    color: Theme.colors.fg.subtle
                                }
                                SignalBars {
                                    anchors.verticalCenter: parent.verticalCenter
                                    level: page.net ? page.net.level(row.n) : 0
                                    size: Theme.typography.sizes.body - 1
                                    color: row.active ? Theme.colors.accent.primary : Theme.colors.fg.muted
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Bluetooth ─────────────────────────────────────────────
    Component {
        id: bluetoothPage

        FocusScope {
            id: btPage
            implicitHeight: btColumn.implicitHeight

            readonly property var bt: root.bt
            readonly property bool powered: bt !== null && bt.powered

            // Discovery runs only while this page is open; it starts again
            // when the adapter comes on with the page open.
            property var heldBt: null
            Component.onCompleted: {
                heldBt = bt;
                heldBt?.setDiscovering(true);
            }
            Component.onDestruction: heldBt?.setDiscovering(false)
            onPoweredChanged: if (powered)
                bt.setDiscovering(true)

            function focusFirst() {
                if (paired.count > 0)
                    paired.itemAt(0)?.forceActiveFocus();
                else if (found.count > 0)
                    found.itemAt(0)?.forceActiveFocus();
                else
                    forceActiveFocus();
            }

            function keepVisible(row) {
                const p = row.mapToItem(btList, 0, 0);
                if (p.y < btFlick.contentY)
                    btFlick.contentY = p.y;
                else if (p.y + row.height > btFlick.contentY + btFlick.height)
                    btFlick.contentY = p.y + row.height - btFlick.height;
            }

            Column {
                id: btColumn
                width: parent.width
                spacing: Theme.metrics.space.sm

                PageHeader {
                    width: parent.width
                    title: "Bluetooth"
                    hasSwitch: true
                    checked: btPage.powered
                    busy: btPage.bt !== null && btPage.bt.busy
                    onBack: stack.back()
                    onToggled: btPage.bt.setPowered(!btPage.bt.powered)
                }

                Note {
                    visible: !btPage.powered
                    text: "Bluetooth is off"
                }

                Flickable {
                    id: btFlick
                    visible: btPage.powered
                    width: parent.width
                    height: Math.min(btList.implicitHeight, 380)
                    contentHeight: btList.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: btList
                        width: parent.width
                        spacing: 2

                        SectionLabel {
                            visible: paired.count > 0
                            text: "My devices"
                        }

                        Repeater {
                            id: paired
                            model: ScriptModel {
                                values: btPage.powered ? btPage.bt.devices : []
                            }

                            StateRow {
                                id: pairedRow
                                required property var modelData
                                readonly property var d: modelData
                                readonly property bool busy: btPage.bt.pending(d)

                                width: btList.width
                                icon: root.deviceIcon(d)
                                title: d.name
                                active: d.connected
                                pending: busy
                                failure: btPage.bt.failures[d.address] === "connect" ? "Couldn't connect. Is it on and in range?" : ""
                                subtitle: {
                                    if (busy)
                                        return d.connected ? "Disconnecting…" : "Connecting…";
                                    const battery = d.batteryAvailable ? " · " + Math.round(d.battery * 100) + "%" : "";
                                    return (d.connected ? "Connected" : "Not connected") + battery;
                                }
                                actions: d.connected ? [
                                    {
                                        id: "disconnect",
                                        label: "Disconnect"
                                    },
                                    {
                                        id: "forget",
                                        label: "Forget",
                                        danger: true
                                    }
                                ] : [
                                    {
                                        id: "forget",
                                        label: "Forget",
                                        danger: true
                                    }
                                ]
                                onClicked: d.connected ? openActions() : btPage.bt.connect(d.address)
                                onAction: id => id === "forget" ? btPage.bt.forget(d.address) : btPage.bt.disconnect(d.address)
                                onActiveFocusChanged: if (activeFocus)
                                    btPage.keepVisible(pairedRow)
                            }
                        }

                        Item {
                            width: parent.width
                            height: nearbyLabel.implicitHeight + Theme.metrics.space.sm

                            SectionLabel {
                                id: nearbyLabel
                                anchors.bottom: parent.bottom
                                text: "Nearby"
                            }
                            Spinner {
                                visible: btPage.bt !== null && btPage.bt.discovering
                                anchors.left: nearbyLabel.right
                                anchors.leftMargin: Theme.metrics.space.sm
                                anchors.verticalCenter: nearbyLabel.verticalCenter
                                size: Theme.typography.sizes.small
                            }
                        }

                        Note {
                            visible: found.count === 0
                            text: btPage.bt && btPage.bt.discovering ? "Looking for devices in pairing mode…" : "No devices found"
                        }

                        Repeater {
                            id: found
                            model: ScriptModel {
                                values: btPage.powered ? btPage.bt.nearby : []
                            }

                            StateRow {
                                id: nearbyRow
                                required property var modelData
                                readonly property var d: modelData

                                width: btList.width
                                icon: root.deviceIcon(d)
                                title: d.name
                                pending: d.pairing
                                subtitle: d.pairing ? "Pairing… confirm on the device if asked" : ""
                                failure: btPage.bt.failures[d.address] === "pair" ? "Pairing failed. Put it in pairing mode and try again." : ""
                                actions: d.pairing ? [
                                    {
                                        id: "cancel",
                                        label: "Cancel"
                                    }
                                ] : []
                                onClicked: btPage.bt.pair(d.address)
                                onAction: btPage.bt.cancelPair(d.address)
                                onActiveFocusChanged: if (activeFocus)
                                    btPage.keepVisible(nearbyRow)
                            }
                        }
                    }
                }
            }
        }
    }
}
