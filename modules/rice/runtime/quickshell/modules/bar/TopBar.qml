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
import "../../services/session"
import "../../services/wallpaper"
import "../../services/notifications"
import "../../services/tray"
import "../../services/mpris"
import "../../services/monitor"

// ── TopBar ────────────────────────────────────────────────────
// Pure compositor (L-001): renders Registry descriptors by region
// and injects declared services (D-009). No widget logic lives here.
// Hidden by default while the legacy bar runs (retires in Phase 8b).
//
// Two frame styles (D-063), chosen by widgets.bar.settings.style:
// "floating" (default) is the rounded rect inset by bar.margin;
// "rail" is flush to the top edge, with a nine-sliced body, a
// recessed plaque behind each region and an end cap at each side.
// A cap that stands in for a widget (power) hides that glance.

PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    readonly property var settings: Theme.widgetConfig("bar").settings ?? ({})
    readonly property bool rail: settings.style === "rail"
    readonly property var frame: rail ? (settings.frame ?? ({})) : ({})
    readonly property var caps: rail ? (settings.caps ?? ({})) : ({})
    readonly property int outerMargin: rail ? 0 : Theme.metrics.bar.margin
    readonly property var capWidgets: [caps.start, caps.end].filter(c => c && c.action === "power").map(() => "power")

    function regionModel(region) {
        return Registry.byRegion(region).filter(d => !bar.capWidgets.includes(d.widgetId));
    }

    visible: ShellState.topBarVisible

    WlrLayershell.namespace: "rice-topbar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }
    // The floating inset is drawn inside the window, not as layer
    // margins: margins committed before the manifest loads were not
    // re-applied when it arrived, so a theme's style could not set them.
    exclusiveZone: Theme.metrics.bar.height + bar.outerMargin
    implicitHeight: Theme.metrics.bar.height + bar.outerMargin
    color: "transparent"
    mask: Region {
        item: frameRoot
    }

    // Service injection map (D-009): the only place service ids
    // resolve to singletons.
    function resolveServices(names) {
        const table = {
            hypr: HyprState,
            network: NetworkState,
            audio: AudioState,
            bluetooth: BluetoothState,
            power: PowerState,
            session: SessionState,
            wallpaper: WallpaperState,
            notifications: NotificationState,
            tray: TrayState,
            mpris: MprisState,
            monitorControl: MonitorControlState
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

            // A glance with nothing to show (width 0) takes no slot,
            // so the row closes up around it (D-064).
            visible: implicitWidth > 0
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
                    if ("screenName" in item)
                        item.screenName = bar.screen.name;
                }
            }
        }
    }

    Item {
        id: frameRoot

        anchors.fill: parent
        anchors.topMargin: bar.outerMargin
        anchors.leftMargin: bar.outerMargin
        anchors.rightMargin: bar.outerMargin

        Rectangle {
            visible: !bar.rail
            anchors.fill: parent
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.base
            opacity: Theme.metrics.bar.opacity
            border.width: 1
            border.color: Theme.colors.bg.surface1
        }

        // Rail body: the theme's nine-sliced piece, or a token-drawn
        // solid with a brass rule along the bottom edge.
        BorderImage {
            readonly property var piece: bar.frame.body ?? null
            visible: bar.rail && piece !== null
            anchors.fill: parent
            source: piece ? Theme.assetUrl(piece.src) : ""
            border.left: piece ? piece.slice[0] : 0
            border.top: piece ? piece.slice[1] : 0
            border.right: piece ? piece.slice[2] : 0
            border.bottom: piece ? piece.slice[3] : 0
            horizontalTileMode: BorderImage.Repeat
        }

        Rectangle {
            visible: bar.rail && !bar.frame.body
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Theme.colors.bg.elevated
                }
                GradientStop {
                    position: 1
                    color: Theme.colors.bg.mantle
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                color: Theme.colors.accent.primary
            }
        }

        RailCap {
            id: startCap
            visible: bar.rail && bar.caps.start !== undefined
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spec: bar.caps.start ?? ({})
            glow: bar.settings.glow ?? ({})
        }

        RailCap {
            id: endCap
            visible: bar.rail && bar.caps.end !== undefined
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spec: bar.caps.end ?? ({})
            glow: bar.settings.glow ?? ({})
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: startCap.visible ? startCap.width + Theme.metrics.space.md : Theme.metrics.space.lg
            anchors.rightMargin: endCap.visible ? endCap.width + Theme.metrics.space.md : Theme.metrics.space.lg
            // Keep the rail's bottom rule clear of contents.
            anchors.bottomMargin: bar.rail ? Theme.metrics.space.xs : 0

            // Startup reveal (D-022): the frame above is present and
            // interactive immediately; only the contents fade in.
            opacity: ShellState.awakened ? 1 : 0
            Behavior on opacity {
                MotionAnim {
                    spec: Motion.awaken
                }
            }

            RailPlaque {
                visible: bar.rail && target.width > 0
                target: leftRow
                piece: bar.frame.plaque ?? null
            }
            RailPlaque {
                visible: bar.rail && target.width > 0
                target: centerRow
                piece: bar.frame.plaque ?? null
            }
            RailPlaque {
                visible: bar.rail && target.width > 0
                target: rightRow
                piece: bar.frame.plaque ?? null
            }

            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: bar.rail ? Theme.metrics.space.sm : 0
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.metrics.bar.spacing

                RegionRepeater {
                    model: bar.regionModel("left")
                }
            }

            Row {
                id: centerRow
                anchors.centerIn: parent
                height: parent.height
                spacing: Theme.metrics.bar.spacing

                RegionRepeater {
                    model: bar.regionModel("center")
                }
            }

            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: bar.rail ? Theme.metrics.space.sm : 0
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                spacing: Theme.metrics.bar.spacing

                RegionRepeater {
                    model: bar.regionModel("right")
                }
            }
        }
    }
}
