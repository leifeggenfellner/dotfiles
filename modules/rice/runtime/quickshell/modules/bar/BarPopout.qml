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
import "../../services/tray"
import "../../services/mpris"
import "../../services/monitor"

// ── BarPopout ─────────────────────────────────────────────────
// The single anchored popout host (L-002): renders the active
// descriptor's popout content below the bar, aligned to its region.
// Click-outside and Esc close. One per screen; only the focused
// screen shows it.
//
// Under the rail bar style (D-070) the popout is a hinged plate: it
// hangs flush from the rail, framed by widgets.bar.settings.frame.popout
// when the theme gives one, and swings down from its top edge on
// Motion.hingeSwing, overshooting a little and settling flat on
// Motion.hingeSettle. Under reduce-motion it only fades.

PanelWindow {
    id: host

    required property var modelData
    screen: modelData

    readonly property var active: ShellState.activePopout.length > 0 ? Registry.effectiveById(ShellState.activePopout) : null
    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === host.screen.name
    readonly property bool open: active !== null && active.popout !== null && onFocusedScreen

    readonly property var barSettings: Theme.widgetConfig("bar").settings ?? ({})
    readonly property bool hinged: barSettings.style === "rail"
    readonly property var plate: hinged ? (barSettings.frame?.popout ?? null) : null
    // Degrees past flat the plate swings before it settles.
    readonly property real overshoot: 2

    function swing() {
        if (!host.hinged)
            return;
        if (host.open) {
            swingDown.restart();
        } else {
            swingDown.stop();
            swingUp.restart();
        }
    }

    // The surface is created already open; a hinged plate starts clear
    // and fades in, so reduce-motion still gets an entrance.
    property bool entered: false

    onOpenChanged: swing()
    Component.onCompleted: {
        entered = true;
        swing();
    }

    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-popout"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    function resolveServices(names) {
        const table = {
            hypr: HyprState,
            network: NetworkState,
            audio: AudioState,
            bluetooth: BluetoothState,
            power: PowerState,
            session: SessionState,
            tray: TrayState,
            mpris: MprisState,
            monitorControl: MonitorControlState
        };
        const out = {};
        for (const n of names)
            out[n] = table[n] ?? null;
        return out;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellState.closePopout()
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closePopout()

        Rectangle {
            id: panel

            readonly property string align: host.active ? host.active.region : "right"

            // Degrees the plate is turned up about its top edge.
            property real hinge: host.hinged && Motion.enabled ? -90 : 0

            anchors.top: parent.top
            // This window already starts below the bar's exclusive zone,
            // so the hinged plate hangs from the window's top edge.
            anchors.topMargin: host.hinged ? 0 : Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
            anchors.right: align === "right" ? parent.right : undefined
            anchors.left: align === "left" ? parent.left : undefined
            anchors.horizontalCenter: align === "center" ? parent.horizontalCenter : undefined
            anchors.rightMargin: Theme.metrics.bar.margin
            anchors.leftMargin: Theme.metrics.bar.margin

            width: content.item ? content.item.width + Theme.metrics.space.lg * 2 : 0
            height: content.item ? content.item.height + Theme.metrics.space.lg * 2 : 0
            radius: host.hinged ? Theme.metrics.radius.small : Theme.metrics.radius.large
            color: host.plate ? "transparent" : Theme.colors.bg.mantle
            border.width: host.plate ? 0 : 1
            border.color: Theme.colors.bg.surface1

            opacity: host.open && (host.entered || !host.hinged) ? 0.98 : 0
            scale: host.open || host.hinged ? 1 : 0.97

            transform: Rotation {
                origin.x: panel.width / 2
                origin.y: 0
                axis {
                    x: 1
                    y: 0
                    z: 0
                }
                angle: panel.hinge
            }

            Behavior on opacity {
                MotionAnim {
                    spec: Motion.calm(host.open ? Motion.panelOpen : Motion.panelClose)
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: host.open ? Motion.panelOpen : Motion.panelClose
                }
            }

            SequentialAnimation {
                id: swingDown
                PropertyAction {
                    target: panel
                    property: "hinge"
                    value: Motion.enabled ? -90 : 0
                }
                MotionAnim {
                    target: panel
                    property: "hinge"
                    to: host.overshoot
                    spec: Motion.hingeSwing
                }
                MotionAnim {
                    target: panel
                    property: "hinge"
                    to: 0
                    spec: Motion.hingeSettle
                }
            }

            MotionAnim {
                id: swingUp
                target: panel
                property: "hinge"
                to: Motion.enabled ? -90 : 0
                spec: Motion.panelClose
            }

            BorderImage {
                visible: host.plate !== null
                anchors.fill: parent
                source: host.plate ? Theme.assetUrl(host.plate.src) : ""
                border.left: host.plate ? host.plate.slice[0] : 0
                border.top: host.plate ? host.plate.slice[1] : 0
                border.right: host.plate ? host.plate.slice[2] : 0
                border.bottom: host.plate ? host.plate.slice[3] : 0
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
            }

            Loader {
                id: content
                x: Theme.metrics.space.lg
                y: Theme.metrics.space.lg
                sourceComponent: host.active ? host.active.popout : null
                onLoaded: {
                    item.services = host.resolveServices(host.active.services);
                    item.settings = host.active.settings;
                }
            }
        }
    }
}
