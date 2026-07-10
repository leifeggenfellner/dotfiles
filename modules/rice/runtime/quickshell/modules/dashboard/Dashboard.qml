import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components/effects"
import "../../widgets"
import "../../services/hypr"
import "../../services/prefs"
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
            prefs: PrefsState,
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
        property real slotWidth: 320
        readonly property bool wide: modelData.widgetId === "epigraph"
        readonly property real naturalWidth: content.item ? Math.max(content.item.width, content.item.implicitWidth) : slotWidth
        readonly property real naturalHeight: content.item ? Math.max(content.item.height, content.item.implicitHeight) : 0
        readonly property real fitScale: naturalWidth > 0 ? Math.min(1, slotWidth / naturalWidth) : 1

        width: slotWidth
        height: Math.ceil(naturalHeight * fitScale)
        clip: true

        Loader {
            id: content
            x: Math.max(0, (mount.width - mount.naturalWidth * mount.fitScale) / 2)
            transformOrigin: Item.TopLeft
            scale: mount.fitScale
            sourceComponent: mount.modelData.glance
            onLoaded: {
                item.services = dashboard.resolveServices(mount.modelData.services);
                item.settings = mount.modelData.settings;
                if (item.theme !== undefined)
                    item.theme = Theme;
                if (item.motion !== undefined)
                    item.motion = Motion;
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

            readonly property int outerMargin: Theme.metrics.space.lg * 2
            readonly property real targetRatio: 1.6
            readonly property int availableWidth: Math.max(1, parent.width - outerMargin * 2)
            readonly property int availableHeight: Math.max(1, parent.height - outerMargin * 2)

            anchors.centerIn: parent
            width: Math.min(availableWidth, 1184, Math.floor(availableHeight * targetRatio))
            height: Math.min(availableHeight, Math.round(width / targetRatio))
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1
            clip: true

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

            InkReveal {
                anchors.fill: parent
                open: dashboard.open
                tint: Theme.colors.fg.subtle
            }

            MouseArea {
                anchors.fill: parent
            }

            Flickable {
                id: viewport

                anchors.fill: parent
                anchors.margins: Theme.metrics.space.lg
                clip: true
                contentWidth: width
                contentHeight: dashboardFlow.height
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                Flow {
                    id: dashboardFlow

                    width: viewport.width
                    spacing: Theme.metrics.space.md

                    Repeater {
                        model: Registry.byRegion("dashboard")

                        DashboardMount {
                            slotWidth: wide ? dashboardFlow.width : (dashboardFlow.width - dashboardFlow.spacing) / 2
                        }
                    }
                }
            }
        }
    }
}
