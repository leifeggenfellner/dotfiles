import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../../components" as Components
import "../../services" as Services
import "../.."
import "./"

PanelWindow {
    id: bar

    required property var modelData

    property var leftWidgets: []
    property var rightWidgets: []
    property var centerWidget: null

    screen: modelData

    WlrLayershell.namespace: "lotm-bar"
    WlrLayershell.layer: WlrLayer.Top
    // Grab keyboard input when the connection panel is open (needed for password TextInput)
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Reserve only the bar strip so overlays can float above workspace content.
    exclusiveZone: Theme.barHeight + margins.top

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Theme.barMargin
        left: Theme.barMargin
        right: Theme.barMargin
    }

    // Keep the bar surface height stable so open/close transitions do not move the bar.
    // Menus still animate internally; this only reserves enough space for them at all times.
    implicitHeight: Theme.barHeight
    color: "transparent"

    // ── Solver feed ─────────────────────────────────────────────
    // Feed this bar's dimensions into the solver for overlay placement.
    // NOTE: the solver is a singleton so two bars (multi-monitor) would race
    // when computing the clock X here.  Clock positioning is instead handled
    // via the per-instance clockX property below.
    onWidthChanged: _updateSolver()
    Component.onCompleted: _updateSolver()

    function _updateSolver() {
        Services.OverlayLayoutSolver.viewportWidth = bar.width;
        Services.OverlayLayoutSolver.viewportHeight = bar.implicitHeight;
        Services.OverlayLayoutSolver.laneGap = Theme.overlayLaneGap;
        Services.OverlayLayoutSolver.leftOccupied = pathwaysSection.width + Theme.barSpacing;
        Services.OverlayLayoutSolver.rightOccupied = rightSection.width + Theme.barSpacing;
    }

    // ── Per-bar clock centering ──────────────────────────────────
    readonly property real clockX: {
        const cw = ritualClock.width;
        const gap = Theme.overlayLaneGap;
        const safeLeft = pathwaysSection.width + Theme.barSpacing + gap;
        const safeRight = bar.width - (rightSection.width + Theme.barSpacing) - gap;
        const idealX = (bar.width - cw) / 2;
        const maxShift = 18;
        if (safeRight - safeLeft >= cw) {
            let resolved = idealX;
            if (resolved < safeLeft)
                resolved = Math.min(idealX + maxShift, safeLeft);
            if (resolved > safeRight - cw)
                resolved = Math.max(idealX - maxShift, safeRight - cw);
            return resolved;
        }
        return idealX;
    }

    // ── Bar background ──────────────────────────────────────────
    Rectangle {
        id: barBackground
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.barHeight
        radius: Theme.barRadius
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, Theme.barOpacity)

        RowLayout {
            id: barLayout
            anchors.fill: barBackground
            anchors.leftMargin: Theme.barSpacing
            anchors.rightMargin: Theme.barSpacing
            spacing: Theme.barSpacing

            // ═══════════ LEFT: Pathways ═══════════
            Components.Pathways {
                id: pathwaysSection
                pathwayData: Services.ThemeLoader.pathways
                activeWorkspace: Services.HyprState.activeWorkspace
                pathwaysDir: Services.ThemeLoader.pathwaysPngDir
                onWidthChanged: bar._updateSolver()
            }

            // ═══════════ SPACER ═══════════
            Item {
                Layout.fillWidth: true
            }

            // ═══════════ RIGHT: widget descriptor row ═══════════
            RowLayout {
                id: rightSection
                spacing: Theme.barSpacing

                // Temporary fallback until Phase 1 descriptors replace these
                Components.ConnectionSigil {
                    visible: bar.rightWidgets.length === 0
                }
                Components.SystemTray {
                    visible: bar.rightWidgets.length === 0
                    pathwayData: Services.ThemeLoader.pathways
                    activeWorkspace: Services.HyprState.activeWorkspace
                    onImplicitWidthChanged: bar._updateSolver()
                }
                PowerSigilMenu {
                    visible: bar.rightWidgets.length === 0
                    pathwaysDir: Services.ThemeLoader.pathwaysDir
                    pathwaysPngDir: Services.ThemeLoader.pathwaysPngDir
                    pathwayCatalog: Services.ThemeLoader.pathwayCatalog
                    pathwayData: Services.ThemeLoader.pathways
                    activeWorkspace: Services.HyprState.activeWorkspace
                }

                Repeater {
                    model: bar.rightWidgets
                    delegate: WidgetMount {
                        descriptor: modelData
                        barModelData: bar.modelData
                    }
                }

                onImplicitWidthChanged: bar._updateSolver()
            }
        }

        // ═══════════ CENTER: Clock (solver-positioned) ═══════════
        Components.RitualClock {
            id: ritualClock
            pathwayData: Services.ThemeLoader.pathways
            activeWorkspace: Services.HyprState.activeWorkspace
            activityLevel: Services.HyprState.activityLevel
            workspacePulse: Services.HyprState.workspacePulse
            cpuLoad: Services.SystemState.cpuLoad
            netLoad: Services.SystemState.netLoad
            z: 5

            // Anchor vertically in bar, horizontal per-bar (not via singleton solver).
            anchors.verticalCenter: barBackground.verticalCenter
            x: bar.clockX

            Behavior on x {
                NumberAnimation {
                    duration: Theme.animDurationOverlay
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
