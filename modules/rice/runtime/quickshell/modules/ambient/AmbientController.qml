import QtQuick
import Quickshell
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

    property bool idleHint: false

    // ── Lock-with-veil handoff (phase 6) ──────────────────────
    // Rice-owned choreography: fade the IdleVeil in, then spawn
    // rice-lock-screen. Every manual/tile/keybind lock path goes
    // through `lock-screen`, which routes here via IPC when rice is
    // up; otherwise it execs the lock directly (no veil).
    property bool lockInFlight: false
    property int lockInFlightSerial: 0
    property string _pendingLockVariant: ""

    readonly property bool ambientAllowed: Theme.motion.ambient && Theme.motion.enabled && Effects.layers.length > 0 && !PrefsState.reduceMotion && PrefsState.ambientMode !== "off" && !PowerState.onBattery && !HyprState.anyFullscreen

    readonly property bool idleAllowed: governor.idleHint && Theme.motion.ambient && Theme.motion.enabled && !PrefsState.reduceMotion && PrefsState.ambientMode !== "off" && !HyprState.anyFullscreen
    readonly property int lockHandoffDelay: PrefsState.reduceMotion ? 0 : 90

    function parseToggle(value) {
        const normalized = String(value).toLowerCase();
        return normalized === "on" || normalized === "true" || normalized === "1" || normalized === "yes";
    }

    function _spawnLock(variant) {
        const args = ["rice-lock-screen"];
        if (variant && variant.length > 0) {
            args.push("--variant");
            args.push(variant);
        }
        Quickshell.execDetached(args);
    }

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

    Binding {
        target: ShellState
        property: "idleApproaching"
        value: governor.idleAllowed
    }

    // Keep the veil handoff brief: it should acknowledge the lock command,
    // not make the user wait before the real lock surface appears.
    Timer {
        id: veilFadeTimer
        interval: governor.lockHandoffDelay
        repeat: false
        onTriggered: {
            const variant = governor._pendingLockVariant;
            governor._pendingLockVariant = "";
            governor._spawnLock(variant);
        }
    }

    // Failsafe: if the spawned lock never actually locks (child crashed,
    // wrong PATH, etc.) the veil would otherwise linger indefinitely.
    // 8s covers even the slowest Quickshell warm-start.
    Timer {
        id: veilWatchdog
        interval: 8000
        repeat: false
        onTriggered: {
            if (!governor.lockInFlight)
                return;
            console.warn("AmbientController: lockWithVeil watchdog fired; clearing veil");
            governor.idleHint = false;
            governor.lockInFlight = false;
        }
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
                fullscreen: HyprState.anyFullscreen,
                idleHint: governor.idleHint,
                idleApproaching: ShellState.idleApproaching,
                lockInFlight: governor.lockInFlight
            });
        }
        function setMode(mode: string): void {
            PrefsState.setAmbientMode(mode);
        }
        function setReduceMotion(v: string): void {
            PrefsState.setReduceMotion(governor.parseToggle(v));
        }
        function setIdleHint(v: string): void {
            const on = governor.parseToggle(v);
            governor.idleHint = on;
            // Off implies lock is done or was aborted — clear inflight
            // regardless of who set it (LOTM unlock, hypridle resume,
            // manual reset). Watchdog is reset to avoid a stale fire.
            if (!on) {
                governor.lockInFlight = false;
                veilWatchdog.stop();
            }
        }

        // Canonical veil-then-lock entry point. `variant` may be empty
        // to let rice-lock-screen resolve its own default (manifest
        // wins). Idempotent within a single fade window.
        function lockWithVeil(variant: string): void {
            if (governor.lockInFlight) {
                console.info("AmbientController: lockWithVeil debounced (inflight)");
                return;
            }
            governor.lockInFlightSerial++;
            governor.lockInFlight = true;
            governor._pendingLockVariant = variant || "";
            governor.idleHint = true;
            veilFadeTimer.restart();
            veilWatchdog.restart();
        }
    }
}
