import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/hypr"

// ── MoodController ───────────────────────────────────────────
// Workspace moods (D-045): a theme may give a named workspace a mood
// in `widgets.mood.settings.workspaces.<name>`:
//
//   effects   ambient layer list replacing the theme's on that screen
//             (same schema and budgets as tokens.effects.layers)
//   backdrop  assets-root path drawn over the wallpaper
//   veil      { tint, wash, density }: fog over the backdrop only — a
//             flat tint wash (≤ 0.6) and a rolling fog sea (≤ 0.9)
//   title     caption shown beside the real workspace name
//   dnd       true → toasts are held while any screen shows it
//   sound     semantic sound event played on entering (muted default)
//
// The mood is derived from HyprState's active workspace names on
// every change and never written to prefs, so leaving the workspace
// or restarting the shell inside it leaves DND and ambient exactly as
// the user set them. Ambient gates (battery, fullscreen, reduce-
// motion) stay with AmbientController.
//
//   quickshell -c rice ipc call mood status

Item {
    id: controller

    readonly property var workspaces: (Theme.widgetConfig("mood").settings ?? {}).workspaces ?? {}

    readonly property var moods: {
        const out = {};
        const names = HyprState.activeWorkspaceNames;
        for (const screen in names) {
            const mood = controller.workspaces[names[screen]];
            if (!mood)
                continue;
            const effects = Array.isArray(mood.effects) && mood.effects.length > 0 ? mood.effects : null;
            out[screen] = {
                workspace: names[screen],
                title: typeof mood.title === "string" ? mood.title : "",
                backdrop: typeof mood.backdrop === "string" ? mood.backdrop : "",
                dnd: mood.dnd === true,
                sound: typeof mood.sound === "string" ? mood.sound : "",
                layers: effects ? Effects.resolve(effects) : null,
                veil: controller._veil(mood.veil)
            };
        }
        return out;
    }

    // The veil only covers the backdrop, under every window, so it may
    // be far denser than the desktop-wide ambient caps.
    function _veil(raw) {
        if (!raw || typeof raw !== "object")
            return null;
        const clamp = (v, fallback, hi) => Math.max(0, Math.min(hi, typeof v === "number" ? v : fallback));
        return {
            tint: Effects.colorRef(raw.tint ?? "fg.subtle"),
            wash: clamp(raw.wash, 0.25, 0.6),
            density: clamp(raw.density, 0.6, 0.9)
        };
    }

    // Startup hydration (or a shell restart inside a mood) must not
    // play the entry sound (D-024): only edges after this settle count.
    property bool _settled: false
    property var _previous: ({})

    Timer {
        interval: 1500
        running: true
        onTriggered: {
            controller._previous = controller.moods;
            controller._settled = true;
        }
    }

    onMoodsChanged: {
        if (!_settled)
            return;
        for (const screen in moods) {
            const mood = moods[screen];
            const before = _previous[screen];
            if (mood.sound && (!before || before.workspace !== mood.workspace))
                Sound.play(mood.sound);
        }
        _previous = moods;
    }

    Binding {
        target: ShellState
        property: "moods"
        value: controller.moods
    }

    IpcHandler {
        target: "mood"

        function status(): string {
            const screens = {};
            for (const screen in ShellState.moods)
                screens[screen] = ShellState.moods[screen].workspace;
            return JSON.stringify({
                configured: Object.keys(controller.workspaces),
                screens: screens,
                quiet: ShellState.moodQuiet,
                doNotDisturb: ShellState.doNotDisturb
            });
        }
    }
}
