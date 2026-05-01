# Skill: Motion and Effects

## Scope

Any animation, transition, visual effect (particles, shaders, glow), or sound in
the runtime or a theme plugin.

## Authority

- **Controls:** the Motion/Sound/Effects facades, the semantic animation
  vocabulary, effect tiers and budgets.
- **Reads:** the motion contract, the `tokens.motion` shape.
- **May not influence:** token *values* (themes own those), widget layout,
  service behavior.

## Rules

- Everything flows through the central facades: `Motion` for animation, `Sound`
  for audio, `Effects` for tiered visual effects. Full rules in
  [contracts/motion-contract.md](../../docs/architecture/contracts/motion-contract.md).
  The rules most violated in practice:
  1. No inline durations, easing curves, or animation Timers in UI code —
     reference semantic animations (`Motion.panelOpen`, `Motion.stateChange`, …).
     If the needed one doesn't exist, name it and add it to `Motion`.
  2. State-driven only (L-007): an animation runs because bound state changed.
     The single exception is the governed ambient tier
     (`tokens.motion.ambient`), which pauses on fullscreen and under
     reduce-motion.
  3. Every animation must be correct with motion disabled — the reduce-motion
     flag collapses transitions to instant.
- Respect effect tiers: T0 transform/opacity always allowed; T1 particles
  budgeted and pausable; T2 shaders per-theme opt-in with mandatory T0
  degradation.
- Motion *feel* (durations, curves, intensity) is theme data
  (`tokens.motion`) — themes tune presets; the engine core never changes per
  theme.
- Keep motion subtle: ≤3 accents visible (L-006); glow derives from tokens,
  never baked into images (L-005); reduce simultaneous moving elements.
- Sounds map semantic events via `tokens.sound`; soundless themes are silent,
  not broken; a global mute pref silences everything.

## Forbidden

- Per-component animation loops or uncleaned timers.
- Permanent/idle animation outside the ambient tier (a DECISIONS rejected idea).
- Effects that don't degrade: a shader without a T0 fallback, a particle system
  that can't pause.
- Token values in this skill or in runtime code — values live in themes.

## Checklist

- [ ] All parameters come from `Motion`/`tokens.motion`.
- [ ] Triggered by state change (or properly registered as ambient).
- [ ] Correct under reduce-motion; pauses on fullscreen if T1/T2.
- [ ] Within budgets (idle ~0% CPU, bar visible <1s at startup).

## Pointers

[motion-contract](../../docs/architecture/contracts/motion-contract.md) ·
[DECISIONS.md](../../docs/architecture/DECISIONS.md) (D-010, L-005..L-007)
