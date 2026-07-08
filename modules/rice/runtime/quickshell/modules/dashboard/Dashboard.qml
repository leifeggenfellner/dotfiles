import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../widgets"
import "../../services/hypr"
import "../../services/system"
import "../../services/weather"

// ── Dashboard ─────────────────────────────────────────────────
// Observatory surface: descriptor-driven dashboard widgets rendered
// from Registry.byRegion("dashboard") with service injection.

PanelWindow {
    id: dashboard

    required property var modelData
    screen: modelData

    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === dashboard.screen.name
    readonly property bool open: ShellState.dashboardOpen && onFocusedScreen

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-dashboard"
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
            systemStats: SystemStatsState,
            weather: WeatherState
        };
        const out = {};
        for (const n of names)
            out[n] = table[n] ?? null;
        return out;
    }

    component DashboardMount: Item {
        id: mount

        required property var modelData

        width: content.item ? Math.max(content.item.width, content.item.implicitWidth) : 0
        height: content.item ? Math.max(content.item.height, content.item.implicitHeight) : 0

        Loader {
            id: content
            sourceComponent: mount.modelData.glance
            onLoaded: {
                item.services = dashboard.resolveServices(mount.modelData.services);
                item.settings = mount.modelData.settings;
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: dashboard.open ? 0.40 : 0

        Behavior on opacity {
            MotionAnim {
                spec: dashboard.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeDashboard()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: dashboard.open
        Keys.onEscapePressed: ShellState.closeDashboard()

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: contentColumn.width + Theme.metrics.space.lg * 2
            height: contentColumn.height + Theme.metrics.space.lg * 2
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: dashboard.open ? 0.96 : 0
            scale: dashboard.open ? 1 : 0.96

            Behavior on opacity {
                MotionAnim {
                    spec: dashboard.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: dashboard.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: contentColumn
                anchors.centerIn: parent
                width: 672
                spacing: Theme.metrics.space.lg

                Repeater {
                    model: Registry.byRegion("dashboard")
                    DashboardMount {}
                }
            }
        }
    }
}
