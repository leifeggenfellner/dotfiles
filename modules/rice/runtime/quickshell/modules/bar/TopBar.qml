import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../widgets"
import "../../services/hypr"
import "../../services/network"
import "../../services/audio"
import "../../services/bluetooth"
import "../../services/power"
import "../../services/wallpaper"
import "../../services/notifications"
import "../../services/tray"

// ── TopBar ────────────────────────────────────────────────────
// Pure compositor (L-001): renders Registry descriptors by region
// and injects declared services (D-009). No widget logic lives here.
// Hidden by default while the legacy bar runs (retires in Phase 8b).

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    visible: ShellState.topBarVisible

    WlrLayershell.namespace: "rice-topbar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: Theme.metrics.bar.margin
        left: Theme.metrics.bar.margin
        right: Theme.metrics.bar.margin
    }

    exclusiveZone: Theme.metrics.bar.height + Theme.metrics.bar.margin
    implicitHeight: Theme.metrics.bar.height
    color: "transparent"

    // Service injection map (D-009): the only place service ids
    // resolve to singletons.
    function resolveServices(names) {
        const table = {
            hypr: HyprState,
            network: NetworkState,
            audio: AudioState,
            bluetooth: BluetoothState,
            power: PowerState,
            wallpaper: WallpaperState,
            notifications: NotificationState,
            tray: TrayState
        };
        const out = {};
        for (const n of names)
            out[n] = table[n] ?? null;
        return out;
    }

    component RegionRepeater: Repeater {
        delegate: Item {
            id: mount

            required property var modelData

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: glanceLoader.item ? glanceLoader.item.implicitWidth : 0
            implicitHeight: glanceLoader.item ? glanceLoader.item.implicitHeight : 0

            // Behind the glance: clicks the glance doesn't consume
            // toggle this widget's popout.
            MouseArea {
                anchors.fill: parent
                enabled: mount.modelData.popout !== null
                onClicked: ShellState.togglePopout(mount.modelData.widgetId)
            }

            Loader {
                id: glanceLoader
                anchors.fill: parent
                sourceComponent: mount.modelData.glance
                onLoaded: {
                    item.services = bar.resolveServices(mount.modelData.services);
                    item.settings = mount.modelData.settings;
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.metrics.radius.large
        color: Theme.colors.bg.base
        opacity: Theme.metrics.bar.opacity
        border.width: 1
        border.color: Theme.colors.bg.surface1
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Theme.metrics.space.lg
        anchors.rightMargin: Theme.metrics.space.lg

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: Theme.metrics.bar.spacing

            RegionRepeater {
                model: Registry.byRegion("left")
            }
        }

        Row {
            anchors.centerIn: parent
            height: parent.height
            spacing: Theme.metrics.bar.spacing

            RegionRepeater {
                model: Registry.byRegion("center")
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            spacing: Theme.metrics.bar.spacing

            RegionRepeater {
                model: Registry.byRegion("right")
            }
        }
    }
}
