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

// ── BarPopout ─────────────────────────────────────────────────
// The single anchored popout host (L-002): renders the active
// descriptor's popout content below the bar, aligned to its region.
// Click-outside and Esc close. One per screen; only the focused
// screen shows it.

PanelWindow {
    id: host

    required property var modelData
    screen: modelData

    readonly property var active: ShellState.activePopout.length > 0
        ? Registry.effectiveById(ShellState.activePopout)
        : null
    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === host.screen.name
    readonly property bool open: active !== null && active.popout !== null && onFocusedScreen

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
            mpris: MprisState
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

            anchors.top: parent.top
            anchors.topMargin: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
            anchors.right: align === "right" ? parent.right : undefined
            anchors.left: align === "left" ? parent.left : undefined
            anchors.horizontalCenter: align === "center" ? parent.horizontalCenter : undefined
            anchors.rightMargin: Theme.metrics.bar.margin
            anchors.leftMargin: Theme.metrics.bar.margin

            width: content.item ? content.item.width + Theme.metrics.space.lg * 2 : 0
            height: content.item ? content.item.height + Theme.metrics.space.lg * 2 : 0
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: host.open ? 0.98 : 0
            scale: host.open ? 1 : 0.97

            Behavior on opacity {
                MotionAnim {
                    spec: host.open ? Motion.panelOpen : Motion.panelClose
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: host.open ? Motion.panelOpen : Motion.panelClose
                }
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
