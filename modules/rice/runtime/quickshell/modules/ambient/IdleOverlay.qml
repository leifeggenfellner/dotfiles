import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components/effects"

// ── IdleOverlay ──────────────────────────────────────────────
// Per-monitor idle warning surface. It sits above application
// windows so the warning is visible, but its empty input region
// means activity still reaches the compositor and cancels hypridle.

PanelWindow {
    id: overlay

    required property var modelData
    screen: modelData

    visible: ShellState.idleApproaching || veil.visible

    WlrLayershell.namespace: "rice-idle"
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

    IdleVeil {
        id: veil
        anchors.fill: parent
        active: ShellState.idleApproaching
        tint: Theme.colors.bg.sunken
        fogTint: Theme.colors.accent.secondary
    }
}
