import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/windows"

// ── InspectorOverlay ─────────────────────────────────────────
// Per-monitor window inspector (D-043): an aura over every visible
// window with its real PID, CPU, memory, process count, and
// workspace. Input-transparent (empty mask) so the desktop stays
// usable underneath; unmapped once hidden and faded out.
//
// Theme-neutral by default. Themes may dress it through
// widgets.inspector.settings:
//   title, subtitle                       header copy
//   labels.{cpu,memory,processes,workspace} diegetic names shown
//                                         BESIDE the plain metric
//   thresholds.{cpuWarn,cpuDanger}        % of one core (25 / 80)
//   thresholds.{memoryWarnMiB,memoryDangerMiB}  (1024 / 4096)
//   tintOpacity                           aura fill (0.08)
// Aura colour follows load: accent.primary → state.warn → state.danger.

PanelWindow {
    id: overlay

    required property var modelData
    screen: modelData

    readonly property bool open: ShellState.inspectorVisible
    readonly property var settings: Theme.widgetConfig("inspector").settings ?? ({})
    readonly property var labels: settings.labels ?? ({})
    readonly property var thresholds: settings.thresholds ?? ({})
    readonly property real tintOpacity: settings.tintOpacity ?? 0.08
    readonly property var windows: WindowStatsState.windows.filter(w => w.monitorName === overlay.modelData.name)

    visible: open || content.opacity > 0.01

    WlrLayershell.namespace: "rice-inspector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {}

    function loadLevel(w) {
        const mib = w.memoryBytes / 1048576;
        if (w.cpuPercent >= (thresholds.cpuDanger ?? 80) || mib >= (thresholds.memoryDangerMiB ?? 4096))
            return 2;
        if (w.cpuPercent >= (thresholds.cpuWarn ?? 25) || mib >= (thresholds.memoryWarnMiB ?? 1024))
            return 1;
        return 0;
    }

    function levelColor(level) {
        return level === 2 ? Theme.colors.state.danger : level === 1 ? Theme.colors.state.warn : Theme.colors.accent.primary;
    }

    // Diegetic label (if the theme names one) always precedes the
    // plain metric name and the real value.
    function metric(key, plain, value) {
        const named = labels[key];
        return (named ? named + " · " : "") + plain + " " + value;
    }

    function formatCpu(percent) {
        return percent < 0 ? "…" : (percent < 10 ? percent.toFixed(1) : Math.round(percent)) + "%";
    }

    function formatBytes(bytes) {
        const mib = bytes / 1048576;
        return mib >= 1024 ? (mib / 1024).toFixed(1) + " GiB" : Math.round(mib) + " MiB";
    }

    Item {
        id: content

        anchors.fill: parent
        opacity: overlay.open ? 1 : 0

        Behavior on opacity {
            MotionAnim {
                spec: overlay.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }

        Repeater {
            model: overlay.windows

            delegate: Item {
                id: aura

                required property var modelData
                readonly property int level: overlay.loadLevel(modelData)
                readonly property color tone: overlay.levelColor(level)
                readonly property bool compact: width < 260 || height < 150

                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.metrics.radius.medium
                    color: Qt.rgba(aura.tone.r, aura.tone.g, aura.tone.b, overlay.tintOpacity)
                    border.width: aura.modelData.focused ? 3 : 2
                    border.color: aura.tone

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }
                }

                Rectangle {
                    id: card

                    x: Theme.metrics.space.md
                    y: Theme.metrics.space.md
                    width: Math.min(details.implicitWidth + Theme.metrics.space.md * 2, aura.width - Theme.metrics.space.md * 2)
                    height: Math.min(details.implicitHeight + Theme.metrics.space.sm * 2, aura.height - Theme.metrics.space.md * 2)
                    visible: width > Theme.metrics.space.lg * 2 && height > Theme.metrics.space.lg
                    clip: true
                    radius: Theme.metrics.radius.small
                    color: Qt.rgba(Theme.colors.bg.elevated.r, Theme.colors.bg.elevated.g, Theme.colors.bg.elevated.b, 0.92)
                    border.width: 1
                    border.color: aura.tone

                    Column {
                        id: details

                        x: Theme.metrics.space.md
                        y: Theme.metrics.space.sm
                        spacing: Theme.metrics.space.xs

                        Text {
                            width: Math.min(implicitWidth, aura.width - Theme.metrics.space.md * 4)
                            text: aura.modelData.title.length > 0 ? aura.modelData.title : aura.modelData.appClass
                            elide: Text.ElideRight
                            color: Theme.colors.fg.primary
                            font.family: Theme.typography.families.display
                            font.pointSize: Theme.typography.sizes.body
                        }

                        Text {
                            text: aura.modelData.appClass + " · PID " + aura.modelData.pid + (aura.modelData.pidWindowCount > 1 ? " · shared by " + aura.modelData.pidWindowCount + " windows" : "")
                            color: Theme.colors.fg.muted
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }

                        Text {
                            text: overlay.metric("cpu", "CPU", overlay.formatCpu(aura.modelData.cpuPercent))
                            color: aura.level > 0 ? aura.tone : Theme.colors.fg.primary
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }

                        Text {
                            text: overlay.metric("memory", "RSS", overlay.formatBytes(aura.modelData.memoryBytes))
                            color: aura.level > 0 ? aura.tone : Theme.colors.fg.primary
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }

                        Text {
                            visible: !aura.compact
                            text: overlay.metric("processes", "processes", aura.modelData.processCount)
                            color: Theme.colors.fg.muted
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }

                        Text {
                            visible: !aura.compact
                            text: overlay.metric("workspace", "workspace", aura.modelData.workspaceName) + (aura.modelData.floating ? " · floating" : "")
                            color: Theme.colors.fg.muted
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.small
                        }
                    }
                }
            }
        }

        Rectangle {
            id: header

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.metrics.space.lg * 2
            width: headerRow.implicitWidth + Theme.metrics.space.lg * 2
            height: headerRow.implicitHeight + Theme.metrics.space.sm * 2
            radius: Theme.metrics.radius.medium
            color: Theme.colors.bg.elevated
            border.width: 1
            border.color: Theme.colors.accent.primary

            Row {
                id: headerRow

                anchors.centerIn: parent
                spacing: Theme.metrics.space.md

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: overlay.settings.title ?? "Window inspector"
                    color: Theme.colors.accent.primary
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.body
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WindowStatsState.error.length > 0 ? WindowStatsState.error : (overlay.settings.subtitle ? overlay.settings.subtitle + " · " : "") + overlay.windows.length + (overlay.windows.length === 1 ? " window" : " windows")
                    color: WindowStatsState.error.length > 0 ? Theme.colors.state.danger : Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }
}
