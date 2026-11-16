pragma Singleton
import QtQuick

// ── Effects ───────────────────────────────────────────────────
// The single reader of ambient-effect config (Theme.effects,
// D-021) and the place effect budgets are enforced STRUCTURALLY:
// a layer this facade does not emit cannot render. Consumers
// (components/effects primitives via modules/ambient) read the
// resolved `layers` list only; whether effects RUN is not decided
// here — that policy lives in modules/ambient/AmbientController,
// which pushes its verdict onto ShellState.ambientActive.
//
// Layer types: fog · particles · vignette · rain. Tints arrive as
// color token refs ("accent.primary") and resolve here (L-005:
// effect colors derive from tokens, never literals).
//
// Conditional presets (D-046): while ShellState.skyConditions holds a
// preset's `when`, its extra layers join the list (before the layer
// budget is applied), its `tints` replace tints by layer type, and its
// `strength` multiplies opacity by layer type (before the caps).
//
// resolve() is also the path for a workspace mood's layer list
// (D-045): modules/mood hands it the theme data, so mood layers
// meet the same budgets without core reading widget settings.

QtObject {
    id: effects

    // Hard budgets (contracts/motion-contract.md). Values beyond
    // these are clamped, not rejected — the theme built, so it
    // renders; it just renders within budget.
    readonly property int maxLayers: 4
    readonly property int maxParticles: 12

    readonly property var presets: (Theme.effects ?? {}).presets ?? []
    readonly property var activePresets: presets.filter(p => ShellState.skyConditions.indexOf(p.when) !== -1)

    readonly property var layers: resolve((Theme.effects ?? {}).layers ?? [])

    function resolve(raw) {
        const active = activePresets;
        const all = raw.slice();
        for (const p of active)
            for (const extra of p.layers ?? [])
                all.push(extra);

        const out = [];
        for (const base of all.slice(0, maxLayers)) {
            let tint = base.tint;
            let gain = 1;
            for (const p of active) {
                const t = (p.tints ?? {})[base.type];
                if (t !== undefined)
                    tint = t;
                const g = (p.strength ?? {})[base.type];
                if (typeof g === "number")
                    gain *= g;
            }
            const l = Object.assign({}, base, {
                tint: tint
            });
            const opacity = fallback => (l.opacity ?? fallback) * gain;

            if (l.type === "fog")
                out.push({
                    type: "fog",
                    tint: _colorRef(l.tint ?? "fg.subtle"),
                    strength: _clamp(opacity(0.10), 0, 0.35),
                    speed: _clamp(l.speed ?? 1.0, 0.1, 3.0),
                    band: l.band ?? "bottom",
                    count: 0
                });
            else if (l.type === "particles")
                out.push({
                    type: "particles",
                    tint: _colorRef(l.tint ?? "accent.primary"),
                    strength: _clamp(opacity(0.30), 0, 0.6),
                    speed: _clamp(l.speed ?? 1.0, 0.1, 3.0),
                    band: "full",
                    count: Math.min(Math.max(1, l.count ?? 8), maxParticles)
                });
            else if (l.type === "vignette")
                out.push({
                    type: "vignette",
                    tint: _colorRef(l.tint ?? "bg.sunken"),
                    strength: _clamp(opacity(0.20), 0, 0.5),
                    speed: 0,
                    band: "full",
                    count: 0
                });
            // Rain is two pre-painted streak textures scrolling, so its
            // `count` is streak density per texture, not live particles.
            else if (l.type === "rain")
                out.push({
                    type: "rain",
                    tint: _colorRef(l.tint ?? "fg.muted"),
                    strength: _clamp(opacity(0.18), 0, 0.35),
                    speed: _clamp(l.speed ?? 1.0, 0.3, 2.0),
                    band: "full",
                    count: Math.min(Math.max(10, l.count ?? 60), 120)
                });
            else
                console.warn("Effects: unknown layer type '" + l.type + "' — skipped");
        }
        return out;
    }

    // Public token-ref resolver for effect data outside `layers`
    // (a mood backdrop's veil, D-045).
    function colorRef(ref) {
        return _colorRef(ref);
    }

    function _clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v));
    }

    // "group.key" → Theme.colors.group.key; unknown refs degrade
    // visibly-sane (fg.subtle) with a warning, never an error.
    function _colorRef(ref) {
        const parts = (typeof ref === "string" ? ref : "").split(".");
        const group = Theme.colors[parts[0]];
        const c = group ? group[parts[1]] : undefined;
        if (c === undefined) {
            console.warn("Effects: unknown color token ref '" + ref + "' — using fg.subtle");
            return Theme.colors.fg.subtle;
        }
        return c;
    }
}
