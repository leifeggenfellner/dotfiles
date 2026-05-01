# Skill: Rice Architecture (router)

## Scope

Entry point for ANY work on the rice framework (Quickshell runtime, themes,
rice Nix modules). Answers: which layer owns this change, where the file goes,
and which specialized skill to apply next.

## Authority

- **Controls:** layer ownership, file placement, routing to specialized skills.
- **Reads:** DECISIONS.md, all contracts.
- **May not influence:** the content of any per-domain rule — it delegates,
  never decides domain questions itself.

## Rules

- Read [docs/architecture/DECISIONS.md](../../docs/architecture/DECISIONS.md)
  before proposing direction; conflicting ideas must cite and supersede an entry,
  never silently redirect.
- Classify the change first, then delegate:
  - Runtime QML structure, imports, state ownership → `quickshell-runtime`
  - Theme package (tokens, assets, manifest, plugins) → `theme-authoring`
  - New/changed widget → `widget-authoring`
  - New/changed service singleton → `service-authoring`
  - Animation, effects, sound → `motion-and-effects`
  - Nix options, manifest builder, switching, propagation → `rice-nix`
- Layer ownership (map in
  [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md)):
  Nix builds and composes · themes provide data + optional plugins · runtime
  renders · services own system state.
- Runtime↔theme coupling is legal only through the
  [theme manifest](../../docs/architecture/contracts/theme-manifest.md) and the
  [widget contract](../../docs/architecture/contracts/widget-contract.md).
- Any agreed decision from a session lands as a new `D-NNN` entry in DECISIONS.md
  in the same change.

## Forbidden

- Per-domain rules in this skill — it only routes.
- Creating new doc locations for architecture content; Law lives in
  `docs/architecture/`, nowhere else.
- Re-litigating entries in the DECISIONS "Rejected ideas" list without a
  superseding entry.

## Checklist

- [ ] Change classified to exactly one owning layer.
- [ ] Relevant specialized skill applied.
- [ ] No conflict with an active DECISIONS entry (or a superseding entry added).
