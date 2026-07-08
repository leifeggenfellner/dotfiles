pragma Singleton
import QtQuick

// ── Theme ─────────────────────────────────────────────────────
// The single facade for theme data (colors, typography, metrics,
// motion tokens, icons). UI code reads Theme.* exclusively.
// Fed by ManifestLoader (defaults ⊕ active theme manifest); the
// property tree mirrors tokens.* in contracts/theme-manifest.md.

QtObject {
    id: theme

    readonly property var _t: ManifestLoader.tokens

    readonly property QtObject colors: QtObject {
        readonly property QtObject bg: QtObject {
            readonly property color base: theme._t.colors.bg.base
            readonly property color mantle: theme._t.colors.bg.mantle
            readonly property color elevated: theme._t.colors.bg.elevated
            readonly property color sunken: theme._t.colors.bg.sunken
            readonly property color surface1: theme._t.colors.bg.surface1
            readonly property color surface2: theme._t.colors.bg.surface2
        }
        readonly property QtObject fg: QtObject {
            readonly property color primary: theme._t.colors.fg.primary
            readonly property color muted: theme._t.colors.fg.muted
            readonly property color subtle: theme._t.colors.fg.subtle
        }
        readonly property QtObject accent: QtObject {
            readonly property color primary: theme._t.colors.accent.primary
            readonly property color secondary: theme._t.colors.accent.secondary
            readonly property color tertiary: theme._t.colors.accent.tertiary
        }
        readonly property QtObject state: QtObject {
            readonly property color ok: theme._t.colors.state.ok
            readonly property color warn: theme._t.colors.state.warn
            readonly property color danger: theme._t.colors.state.danger
            readonly property color info: theme._t.colors.state.info
        }
    }

    readonly property QtObject typography: QtObject {
        readonly property QtObject families: QtObject {
            readonly property string display: theme._t.typography.families.display
            readonly property string sans: theme._t.typography.families.sans
            readonly property string mono: theme._t.typography.families.mono
        }
        readonly property QtObject sizes: QtObject {
            readonly property int small: theme._t.typography.sizes.small
            readonly property int body: theme._t.typography.sizes.body
            readonly property int bar: theme._t.typography.sizes.bar
            readonly property int heading: theme._t.typography.sizes.heading
            readonly property int icon: theme._t.typography.sizes.icon
        }
        readonly property QtObject weights: QtObject {
            readonly property int regular: Font.Normal
            readonly property int medium: Font.Medium
            readonly property int bold: Font.Bold
        }
    }

    readonly property QtObject metrics: QtObject {
        readonly property QtObject radius: QtObject {
            readonly property int small: theme._t.metrics.radius.small
            readonly property int medium: theme._t.metrics.radius.medium
            readonly property int large: theme._t.metrics.radius.large
        }
        readonly property QtObject space: QtObject {
            readonly property int xs: theme._t.metrics.space.xs
            readonly property int sm: theme._t.metrics.space.sm
            readonly property int md: theme._t.metrics.space.md
            readonly property int lg: theme._t.metrics.space.lg
        }
        readonly property QtObject bar: QtObject {
            readonly property int height: theme._t.metrics.bar.height
            readonly property int margin: theme._t.metrics.bar.margin
            readonly property int spacing: theme._t.metrics.bar.spacing
            readonly property real opacity: theme._t.metrics.bar.opacity
        }
    }

    readonly property QtObject motion: QtObject {
        readonly property QtObject durations: QtObject {
            readonly property int fast: theme._t.motion.durations.fast
            readonly property int base: theme._t.motion.durations.base
            readonly property int slow: theme._t.motion.durations.slow
            readonly property int overlay: theme._t.motion.durations.overlay
            // Optional (D-022): reserved for infrequent, deliberate
            // moments. Falls back to slow so themes that never
            // declare it keep one coherent tempo.
            readonly property int ceremonial: theme._t.motion.durations.ceremonial ?? theme._t.motion.durations.slow
        }
        // Named curve specs from the manifest (D-022) — previously
        // declared in the contract but ignored by the runtime.
        readonly property QtObject easings: QtObject {
            readonly property int standard: theme._easing(theme._t.motion.easings.standard)
            readonly property int enter: theme._easing(theme._t.motion.easings.enter)
            readonly property int exit: theme._easing(theme._t.motion.easings.exit)
            readonly property int emphasis: theme._easing(theme._t.motion.easings.emphasis)
        }
        readonly property bool ambient: theme._t.motion.ambient ?? false
        readonly property bool enabled: theme._t.motion.enabled
    }

    // Raw ambient-effect config (D-021). Read ONLY by core/Effects,
    // which resolves tint token refs and enforces the budgets.
    readonly property var effects: theme._t.effects ?? ({
            layers: []
        })

    // Curve-name string → Easing enum. Unknown names degrade to
    // OutCubic with a warning — a theme typo never breaks motion.
    function _easing(name) {
        const v = ({
                "Linear": Easing.Linear,
                "InQuad": Easing.InQuad,
                "OutQuad": Easing.OutQuad,
                "InOutQuad": Easing.InOutQuad,
                "InCubic": Easing.InCubic,
                "OutCubic": Easing.OutCubic,
                "InOutCubic": Easing.InOutCubic,
                "InQuart": Easing.InQuart,
                "OutQuart": Easing.OutQuart,
                "InOutQuart": Easing.InOutQuart,
                "InQuint": Easing.InQuint,
                "OutQuint": Easing.OutQuint,
                "InOutQuint": Easing.InOutQuint,
                "InExpo": Easing.InExpo,
                "OutExpo": Easing.OutExpo,
                "InOutExpo": Easing.InOutExpo,
                "InSine": Easing.InSine,
                "OutSine": Easing.OutSine,
                "InOutSine": Easing.InOutSine,
                "InBack": Easing.InBack,
                "OutBack": Easing.OutBack,
                "InOutBack": Easing.InOutBack,
                "InElastic": Easing.InElastic,
                "OutElastic": Easing.OutElastic,
                "InBounce": Easing.InBounce,
                "OutBounce": Easing.OutBounce
            })[name];
        if (v === undefined) {
            console.warn("Theme: unknown easing curve '" + name + "' — using OutCubic");
            return Easing.OutCubic;
        }
        return v;
    }

    // ── Icons ─────────────────────────────────────────────────
    // Resolve a semantic icon name. Values containing "/" are
    // files relative to the theme's assets root (returned as a
    // file:// URL); anything else is a font glyph.
    function icon(name) {
        const v = ManifestLoader.icons[name];
        return v !== undefined ? v : ManifestLoader.icons["unknown"];
    }
    function iconIsFile(value) {
        return typeof value === "string" && value.indexOf("/") !== -1;
    }
    function iconUrl(value) {
        // Empty during the pre-merge binding pass; Image treats "" as no-op.
        const root = ManifestLoader.assetsRoot;
        return root.length > 0 ? "file://" + root + "/" + value : "";
    }

    // ── Assets & widget config ────────────────────────────────
    // assetUrl specs: "raster:<set>/<file>" → build-time raster output;
    // "/abs/path" → as-is; anything else → theme assets root relative.
    function assetUrl(spec) {
        if (typeof spec !== "string" || spec.length === 0)
            return "";
        if (spec.startsWith("raster:")) {
            const rest = spec.slice(7);
            const cut = rest.indexOf("/");
            if (cut < 0)
                return "";
            const dir = ManifestLoader.manifest.assets.raster[rest.slice(0, cut)];
            return dir ? "file://" + dir + "/" + rest.slice(cut + 1) : "";
        }
        if (spec.startsWith("/"))
            return "file://" + spec;
        return iconUrl(spec);
    }

    function soundUrl(name) {
        const spec = (ManifestLoader.manifest.assets.sounds ?? {})[name];
        return spec ? assetUrl(spec) : "";
    }

    // Per-widget manifest config (contracts/widget-contract.md).
    function widgetConfig(widgetId) {
        return ManifestLoader.manifest.widgets[widgetId] ?? ({});
    }

    readonly property var plugins: ManifestLoader.manifest.plugins ?? []

    // Active theme's wallpaper set (store paths; may be empty) —
    // build-derived from assets/wallpapers/ (D-019).
    readonly property var wallpapers: ManifestLoader.manifest.assets.wallpapers ?? []

    // ── Theme catalog (switch machinery, D-018) ───────────────
    // Every Nix-built theme from the themes.json index; empty when
    // the index is absent (dev run without a rebuild).
    readonly property string activeName: ManifestLoader.activeTheme
    readonly property var catalog: {
        const idx = ManifestLoader.themesIndex;
        return Object.keys(idx).sort().map(n => ({
                    name: n,
                    displayName: idx[n].displayName ?? n,
                    preview: idx[n].preview ? "file://" + idx[n].preview : ""
                }));
    }
}
