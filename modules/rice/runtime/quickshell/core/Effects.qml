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
// Layer types v1: fog · particles · vignette. Tints arrive as
// color token refs ("accent.primary") and resolve here (L-005:
// effect colors derive from tokens, never literals).

QtObject {
    id: effects

    // Hard budgets (contracts/motion-contract.md). Values beyond
    // these are clamped, not rejected — the theme built, so it
    // renders; it just renders within budget.
    readonly property int maxLayers: 4
    readonly property int maxParticles: 12

    readonly property var layers: {
        const raw = (Theme.effects ?? {}).layers ?? [];
        const out = [];
        for (const l of raw.slice(0, maxLayers)) {
            if (l.type === "fog")
                out.push({
                    type: "fog",
                    tint: _colorRef(l.tint ?? "fg.subtle"),
                    strength: _clamp(l.opacity ?? 0.10, 0, 0.35),
                    speed: _clamp(l.speed ?? 1.0, 0.1, 3.0),
                    band: l.band ?? "bottom",
                    count: 0
                });
            else if (l.type === "particles")
                out.push({
                    type: "particles",
                    tint: _colorRef(l.tint ?? "accent.primary"),
                    strength: _clamp(l.opacity ?? 0.30, 0, 0.6),
                    speed: _clamp(l.speed ?? 1.0, 0.1, 3.0),
                    band: "full",
                    count: Math.min(Math.max(1, l.count ?? 8), maxParticles)
                });
            else if (l.type === "vignette")
                out.push({
                    type: "vignette",
                    tint: _colorRef(l.tint ?? "bg.sunken"),
                    strength: _clamp(l.opacity ?? 0.20, 0, 0.5),
                    speed: 0,
                    band: "full",
                    count: 0
                });
            else
                console.warn("Effects: unknown layer type '" + l.type + "' — skipped");
        }
        return out;
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
