# Skill: Quickshell Runtime

## Scope

Structure and hygiene of the theme-agnostic runtime at
`modules/rice/runtime/quickshell/`: file placement, import direction, state
ownership. (During migration, the legacy location is
`modules/programs/quickshell/ui/` — same rules apply.)

## Authority

- **Controls:** runtime tree layout, import direction, where state ownership lives.
- **Reads:** the contracts, ARCHITECTURE.md.
- **May not influence:** theme content or manifest shape, the Nix option surface,
  the internals of individual widgets/services (only their placement and imports).

## Rules

- Place files by layer: `utils/` pure helpers · `core/` facades
  (Theme, Motion, Sound, ManifestLoader, ShellState) · `components/` pure
  presentation · `widgets/` descriptor-driven widgets · `modules/` surfaces
  (bar, launcher, osd, …) · `services/` state singletons.
- Import direction is a strict DAG — full table in
  [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md). The three most
  violated rules:
  1. `components/` never import services.
  2. `services/` import only `utils/` — no UI, no `Theme`.
  3. Only `ManifestLoader` reads manifest JSON; everything else goes through
     the `Theme` facade.
- State lives in exactly one of three places: services (system state),
  `ShellState` (UI state), `PrefsState` (persisted prefs). Never in widgets.
- The runtime is theme-blind (D-006): no theme-name literals, no theme asset
  catalogs, theme-neutral component names.
- Surfaces are lazy (`Loader`/`LazyLoader`); only the bar is eager.
- Every folder ships a `qmldir`; one public PascalCase type per file.
- Run `scripts/rice-lint.sh` (once it exists) after structural changes; it
  enforces the import allowlist and the theme-literal ban.

## Forbidden

- Feature logic in `shell.qml` or surface compositors — they iterate
  descriptors and delegate.
- Hardcoded colors, spacing, fonts, durations (L-004, D-010).
- Upward imports (e.g. a component importing a widget) or service-to-service
  imports.
- Big-bang tree moves; migrate in small validated batches with compatibility
  imports.

## Checklist

- [ ] New files match the layer taxonomy.
- [ ] No import-direction violations introduced.
- [ ] No theme literals or raw style values under `runtime/`.
- [ ] State ownership explicit (service / ShellState / PrefsState).

## Pointers

[ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md) ·
[service-contract](../../docs/architecture/contracts/service-contract.md) ·
[widget-contract](../../docs/architecture/contracts/widget-contract.md)
