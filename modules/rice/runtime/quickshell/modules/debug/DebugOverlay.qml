import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/audio"
import "../../services/network"
import "../../services/bluetooth"
import "../../services/notifications"
import "../../services/wallpaper"
import "../../services/hypr"

// ── DebugOverlay ──────────────────────────────────────────────
// Every dynamic fact, inspectable (design principle 9). Read-only
// corner panel: theme source, shell state, service states, and
// this overlay's own frame rate (≈0 when idle proves the
// steady-state budget in contracts/motion-contract.md).

PanelWindow {
    id: debug

    required property var modelData
    screen: modelData

    visible: ShellState.debugVisible

    WlrLayershell.namespace: "rice-debug"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
    }
    margins {
        top: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        left: Theme.metrics.bar.margin
    }

    implicitWidth: 340
    implicitHeight: column.height + Theme.metrics.space.lg * 2
    color: "transparent"

    property int fps: 0
    property int _frames: 0

    Connections {
        target: content.Window.window
        function onFrameSwapped() {
            debug._frames++;
        }
    }

    Timer {
        interval: 1000
        running: debug.visible
        repeat: true
        onTriggered: {
            debug.fps = debug._frames;
            debug._frames = 0;
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        radius: Theme.metrics.radius.medium
        color: Theme.colors.bg.sunken
        opacity: 0.92
        border.width: 1
        border.color: Theme.colors.bg.surface1

        Column {
            id: column
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: Theme.metrics.space.lg
            spacing: Theme.metrics.space.xs

            component DebugRow: Text {
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }

            Text {
                text: "rice debug"
                color: Theme.colors.accent.primary
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.body
                font.weight: Theme.typography.weights.bold
            }

            DebugRow { text: "screen      " + debug.modelData.name }
            DebugRow {
                text: "theme       " + (ManifestLoader.loaded
                    ? ManifestLoader.meta.displayName + " (" + ManifestLoader.manifestPath + ")"
                    : "runtime defaults (no manifest)")
            }
            DebugRow {
                text: "motion      " + (Motion.enabled ? "enabled" : "disabled")
                    + (ShellState.reduceMotion ? " (reduce-motion)" : "")
            }
            DebugRow {
                text: "ambient     " + (ShellState.ambientActive ? "active" : "off")
                    + " · layers:" + Effects.layers.length
                    + (HyprState.anyFullscreen ? " · fullscreen" : "")
            }
            DebugRow { text: "overlay fps " + debug.fps }
            DebugRow { text: "" }
            DebugRow {
                text: "surfaces    launcher:" + (ShellState.launcherOpen ? 1 : 0)
                    + " dash:" + (ShellState.dashboardOpen ? 1 : 0)
                    + " notif:" + (ShellState.notificationsOpen ? 1 : 0)
                    + " osd:" + (ShellState.osdVisible ? 1 : 0)
                    + " bar:" + (ShellState.topBarVisible ? 1 : 0)
            }
            DebugRow { text: "" }
            DebugRow {
                text: "hypr        " + (HyprState.available
                    ? "focused: " + (HyprState.focusedScreenName || "?")
                    : "unavailable")
            }
            component ServiceTag: QtObject {
                function tag(svc) {
                    return svc.mock ? "MOCK " : (svc.available ? "live " : "n/a  ");
                }
            }
            ServiceTag { id: tags }

            DebugRow {
                text: "audio  " + tags.tag(AudioState) + "vol:" + Math.round(AudioState.volume * 100) + "%"
                    + (AudioState.muted ? " muted" : "")
            }
            DebugRow {
                text: "wall   " + tags.tag(WallpaperState) + (WallpaperState.current.length > 0
                    ? WallpaperState.current.split("/").pop()
                    : "none") + (WallpaperState.error.length > 0 ? " !" + WallpaperState.error : "")
            }
            DebugRow {
                text: "net    " + tags.tag(NetworkState) + (NetworkState.connected
                    ? NetworkState.ssid + " (" + Math.round(NetworkState.strength * 100) + "%)"
                    : "disconnected")
            }
            DebugRow {
                text: "bt     " + tags.tag(BluetoothState) + (BluetoothState.powered ? "on" : "off")
                    + " · " + BluetoothState.devices.filter(d => d.connected).length + " connected"
            }
            DebugRow {
                text: "notifs " + tags.tag(NotificationState) + NotificationState.notifications.length + " pending"
            }
        }
    }
}
