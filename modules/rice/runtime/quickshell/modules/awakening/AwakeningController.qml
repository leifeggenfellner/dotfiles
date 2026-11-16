import Quickshell.Io
import QtQuick
import "../../core"
import "../../services/prefs"

// ── AwakeningController ──────────────────────────────────────
// Session awakening (D-053): the first shell start of a login plays a
// full-screen fog-lift. A theme opts in with `widgets.awakening.settings`:
//
//   title     line shown while the fog holds (required to opt in)
//   subtitle  smaller line under it
//   hold      ms the fog holds before lifting (0–3000, default 900)
//   lift      ms the fog takes to lift (300–5000, default 2400)
//   sound     semantic sound event played as it starts (muted default)
//
// Once per session: a marker in $XDG_RUNTIME_DIR keyed by the Hyprland
// instance signature. rice-shell restarts and rebuilds run inside the
// same Hyprland instance and find it, so only a fresh login plays. The
// marker is written even when the theme has no ritual, so switching
// theme mid-session never plays one late. Reduce-motion collapses it to
// nothing; the overlay never takes input either way.
//
//   quickshell -c rice ipc call awakening status
//   quickshell -c rice ipc call awakening trigger   (forced, for tests)

Item {
    id: controller

    readonly property var settings: Theme.widgetConfig("awakening").settings ?? ({})
    readonly property bool configured: typeof settings.title === "string" && settings.title.length > 0
    readonly property int hold: _ms(settings.hold, 900, 0, 3000)
    readonly property int lift: _ms(settings.lift, 2400, 300, 5000)

    // "pending" until prefs and manifest are read, then the outcome of
    // the session check: played | seen | unconfigured | reduced.
    property string lastResult: "pending"
    property bool _checked: false
    readonly property bool _ready: PrefsState.ready && ManifestLoader.loaded

    on_ReadyChanged: _check()
    Component.onCompleted: _check()

    function _ms(value, fallback, lo, hi) {
        return Math.max(lo, Math.min(hi, typeof value === "number" ? Math.round(value) : fallback));
    }

    function _check() {
        if (_checked || !_ready)
            return;
        _checked = true;
        marker.running = true;
    }

    // Returns the outcome; plays only when the theme opts in and motion
    // is allowed.
    function play() {
        if (!configured)
            return "unconfigured";
        if (!Motion.enabled)
            return "reduced";
        if (ShellState.awakening !== null)
            return "played";
        Sound.play(settings.sound ?? "");
        ShellState.awakening = {
            title: settings.title,
            subtitle: typeof settings.subtitle === "string" ? settings.subtitle : "",
            hold: hold,
            lift: lift
        };
        done.interval = hold + lift + 400;
        done.restart();
        return "played";
    }

    Process {
        id: marker
        command: ["sh", "-c", "m=\"${XDG_RUNTIME_DIR:-/tmp}/rice-awakened-${HYPRLAND_INSTANCE_SIGNATURE:-none}\"; [ -e \"$m\" ] && exit 1; : > \"$m\""]
        onExited: code => controller.lastResult = code === 0 ? controller.play() : "seen"
    }

    Timer {
        id: done
        onTriggered: ShellState.awakening = null
    }

    IpcHandler {
        target: "awakening"

        function status(): string {
            return JSON.stringify({
                configured: controller.configured,
                active: ShellState.awakening !== null,
                lastResult: controller.lastResult,
                hold: controller.hold,
                lift: controller.lift
            });
        }

        function trigger(): string {
            controller.lastResult = controller.play();
            return controller.lastResult;
        }
    }
}
