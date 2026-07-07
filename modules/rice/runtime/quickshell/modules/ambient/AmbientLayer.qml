import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components/effects"

// ── AmbientLayer ──────────────────────────────────────────────
// Per-monitor atmosphere surface (D-021): mounts the theme's
// resolved effect layers (core/Effects) between the wallpaper and
// application windows. Input-transparent (empty mask) and mapped
// only while the governor says so — when ambient is off the window
// is unmapped and the Loader unloaded, so the steady-state cost is
// exactly zero (motion-contract budget).

PanelWindow {
    id: layerWin

    required property var modelData
    screen: modelData

    visible: ShellState.ambientActive && Effects.layers.length > 0

    WlrLayershell.namespace: "rice-ambient"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Empty input region: every event passes through to the desktop.
    mask: Region {}

    Loader {
        anchors.fill: parent
        active: layerWin.visible

        sourceComponent: Item {
            Repeater {
                model: Effects.layers

                Loader {
                    id: effectMount

                    required property var modelData

                    anchors.fill: parent
                    sourceComponent: modelData.type === "fog" ? fogComponent
                        : modelData.type === "particles" ? particleComponent
                        : modelData.type === "vignette" ? vignetteComponent
                        : null

                    onLoaded: {
                        item.tint = modelData.tint;
                        item.strength = modelData.strength;
                        if (modelData.type === "fog") {
                            item.speed = modelData.speed;
                            item.band = modelData.band;
                        } else if (modelData.type === "particles") {
                            item.speed = modelData.speed;
                            item.count = modelData.count;
                        }
                    }
                }
            }

            Component {
                id: fogComponent
                FogLayer {
                    running: ShellState.ambientActive
                }
            }
            Component {
                id: particleComponent
                ParticleField {
                    running: ShellState.ambientActive
                }
            }
            Component {
                id: vignetteComponent
                VignetteLayer {}
            }
        }
    }
}
