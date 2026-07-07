import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/prefs"
import "../../services/power"
import "../../services/hypr"

// ── AmbientController ─────────────────────────────────────────
// The ambient governor (D-021): the ONLY place the run/pause
// policy for atmosphere effects lives. It composes user prefs
// (reduce-motion, ambient mode) with system state (battery,
// fullscreen) and pushes the verdict onto ShellState — because
// core and components may not import services, this modules-layer
// bridge is how the motion contract's T1 gating stays layer-legal.
//
// Instantiated once in shell.qml (not a singleton: it must run
// even when no ambient surface exists, since it also forwards the
// global reduce-motion pref that gates ALL motion).

Item {
    id: governor

    readonly property bool ambientAllowed: Theme.motion.ambient
        && Theme.motion.enabled
        && Effects.layers.length > 0
        && !PrefsState.reduceMotion
        && PrefsState.ambientMode !== "off"
        && !PowerState.onBattery
        && !HyprState.anyFullscreen

    Binding {
        target: ShellState
        property: "reduceMotion"
        value: PrefsState.reduceMotion
    }

    Binding {
        target: ShellState
        property: "ambientActive"
        value: governor.ambientAllowed
    }

    IpcHandler {
        target: "ambient"

        function status(): string {
            return JSON.stringify({
                active: ShellState.ambientActive,
                mode: PrefsState.ambientMode,
                reduceMotion: PrefsState.reduceMotion,
                themeAmbient: Theme.motion.ambient,
                layers: Effects.layers.length,
                onBattery: PowerState.onBattery,
                fullscreen: HyprState.anyFullscreen
            });
        }
        function setMode(mode: string): void {
            PrefsState.setAmbientMode(mode);
        }
        function setReduceMotion(v: string): void {
            PrefsState.setReduceMotion(v === "on" || v === "true" || v === "1");
        }
    }
}
