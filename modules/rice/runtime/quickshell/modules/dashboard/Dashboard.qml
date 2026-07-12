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
// Dashboard v2: Observatory surface rendered from descriptor-driven cards.

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

    readonly property bool surfaceActive: open

    function resolveServices(names) {
        const table = {
            prefs: PrefsState,
            systemStats: SystemStatsState,
            weather: WeatherState
        };
        const out = {};
        for (const n of (names ?? []))
            out[n] = table[n] ?? null;
        return out;
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
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Left) {
                dashboardGrid.moveFocus("left");
                event.accepted = true;
            } else if (event.key === Qt.Key_Right) {
                dashboardGrid.moveFocus("right");
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                dashboardGrid.moveFocus("up");
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                dashboardGrid.moveFocus("down");
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab) {
                dashboardGrid.focusNext(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Backtab) {
                dashboardGrid.focusNext(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                dashboardGrid.activateFocused();
                event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
                viewport.contentY = Math.min(viewport.contentHeight - viewport.height, viewport.contentY + viewport.height * 0.82);
                event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
                viewport.contentY = Math.max(0, viewport.contentY - viewport.height * 0.82);
                event.accepted = true;
            }
        }

        Rectangle {
            id: panel

            readonly property int outerMargin: Theme.metrics.space.lg * 2
            readonly property real targetRatio: 1.6
            readonly property int availableWidth: Math.max(1, parent.width - outerMargin * 2)
            readonly property int availableHeight: Math.max(1, parent.height - outerMargin * 2)
            readonly property bool compactPanel: availableWidth < 900

            anchors.centerIn: parent
            width: Math.min(availableWidth, 1184, Math.floor(availableHeight * targetRatio))
            height: compactPanel ? Math.min(availableHeight, Math.max(Math.round(width / 0.72), Math.round(width / targetRatio))) : Math.min(availableHeight, Math.round(width / targetRatio))
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

            Item {
                anchors.fill: parent
                opacity: 0.16

                Repeater {
                    model: 64

                    Rectangle {
                        width: 1 + (index % 3)
                        height: 1
                        x: (index * 47) % Math.max(1, panel.width)
                        y: (index * 89) % Math.max(1, panel.height)
                        radius: 1
                        color: index % 2 === 0 ? Theme.colors.fg.subtle : Theme.colors.accent.secondary
                        opacity: 0.18 + (index % 5) * 0.03
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "☉"
                color: Theme.colors.accent.secondary
                opacity: 0.055
                font.family: Theme.typography.families.display
                font.pointSize: Math.min(panel.width, panel.height) * 0.46
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.metrics.space.lg * 2
                color: Theme.colors.bg.sunken
                opacity: 0.16
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.metrics.space.lg * 2
                color: Theme.colors.bg.sunken
                opacity: 0.18
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: Theme.metrics.space.lg * 2
                color: Theme.colors.bg.sunken
                opacity: 0.12
            }

            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: Theme.metrics.space.lg * 2
                color: Theme.colors.bg.sunken
                opacity: 0.12
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
                contentHeight: dashboardGrid.contentHeight
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height

                function ensureVisible(y, h) {
                    const top = Math.max(0, y - Theme.metrics.space.md);
                    const bottom = y + h + Theme.metrics.space.md;
                    if (top < contentY)
                        contentY = top;
                    else if (bottom > contentY + height)
                        contentY = Math.min(contentHeight - height, bottom - height);
                }

                DashboardGrid {
                    id: dashboardGrid

                    anchors.top: parent.top
                    anchors.left: parent.left
                    width: viewport.width
                    height: Math.max(viewport.height, contentHeight)
                    descriptors: Registry.byRegion("dashboard")
                    serviceResolver: dashboard.resolveServices
                    surfaceActive: dashboard.surfaceActive
                    surfaceMapped: panel.opacity > 0.01
                    reducedMotion: PrefsState.reduceMotion
                    onRequestVisible: (y, h) => viewport.ensureVisible(y, h)
                }
            }
        }
    }
}
