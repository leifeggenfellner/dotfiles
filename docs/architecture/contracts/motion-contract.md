# Contract: Motion, Effects & Sound

Governs all animation, visual effects, and sound in the runtime (D-010, L-007).
Motion exists to reinforce state changes and atmosphere — never for its own sake.

## Motion tokens (from the theme manifest)

```text
tokens.motion.durations  { fast, base, slow, overlay }      # ms
tokens.motion.easings    { standard, enter, exit, emphasis } # named curve specs
tokens.motion.intensity  "calm" | "lively"                   # global scaler hint
tokens.motion.ambient    bool                                 # opt-in ambient tier
tokens.motion.enabled    bool                                 # theme-level kill switch
tokens.sound             { event → file }                     # optional event map
```

## The Motion singleton

`core/Motion.qml` is the only source of animation parameters. It exposes
**semantic animations** — `Motion.panelOpen`, `Motion.popoutIn`, `Motion.popoutOut`,
`Motion.stateChange`, `Motion.glowPulse`, … — each resolving duration + easing from
the motion tokens.

Rules:

1. **No inline durations, curves, or one-off Timers for animation** anywhere in
   UI code. Widgets and components reference `Motion.*` only.
2. **State-driven only:** an animation runs because a bound state changed. No idle
   loops outside the ambient tier below.
3. A global **reduce-motion flag** (user pref via `PrefsState`, plus
   `tokens.motion.enabled`) collapses all animations to instant transitions.
   Every animation must be correct with motion disabled.
4. New semantic animation names are added to `Motion` — not invented ad hoc in
   widgets. If two widgets need the same feel, it gets a name.

## Effect tiers

| Tier | What | Rules |
|---|---|---|
| **T0** | transform + opacity animations | Always allowed. The baseline every effect must degrade to. |
| **T1** | canvas/particle effects (fog, embers, drift) | Budgeted and pausable. Paused when a fullscreen client is active and under reduce-motion. |
| **T2** | shader effects | Per-theme opt-in. Must ship a T0 degradation path; failure to compile falls back silently. |

**Ambient tier:** themes may declare idle atmosphere effects (T1/T2) via
`tokens.motion.ambient = true`. Ambient effects run only when ambient is on AND
reduce-motion is off, pause on fullscreen, and count against the budgets below.
This is the single governed exception to rule 2 (L-007 generalized by D-010).

## Budgets

- Startup: bar visible in < 1s.
- Steady state: ~0% CPU when idle with ambient off; ambient effects must not keep
  the compositor permanently redrawing at full frame rate.
- Accent discipline: ≤ 3 accent colors visible simultaneously (L-006).
- Glow and highlight colors derive from tokens, never baked into images (L-005).

## Sound

- `core/Sound.qml` maps semantic events (`themeSwitch`, `notification`,
  `popoutOpen`, …) to files from `tokens.sound`.
- Themes without a sound map are silent — never broken; missing events are no-ops.
- Sounds fire on the same state changes that drive motion; no sound loops.
- A global mute pref (via `PrefsState`) silences everything.
