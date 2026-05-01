# Skill: Rice Nix

## Scope

Nix modules of the rice framework: the `rice.*` option surface, theme manifest
building, theme switching machinery, and propagation to GTK/Qt/cursor/fonts/
hyprlock/wallpaper. Companion to the general `nix-module-quality` skill.

## Authority

- **Controls:** the `rice.*` option surface, manifest generation, switch
  machinery, propagation wiring.
- **Reads:** the theme-manifest contract, repo Nix conventions.
- **May not influence:** QML structure or runtime behavior, widget/service
  internals — Nix builds and composes; it never dictates how the shell works.

## Rules

- Framework Nix lives under `modules/rice/nix/` (options, `mkThemeManifest`,
  switch machinery, propagation); theme data under `modules/rice/themes/<name>/`.
  Follow repo conventions: `flake.homeModules.rice-*` /
  `flake.nixosModules.rice-*`, options under `rice.*`, underscore-prefixed
  non-module files, discovery via import-tree.
- Option surface: `rice.enable` · `rice.theme` (Nix-default active) ·
  `rice.themes.<name>.enable` (what gets built) · host-level overrides via
  `rice.settings` merged into the manifest.
- Two-layer switch (D-003): build ALL enabled themes + `themes.json` index into
  the store; runtime follows the `$XDG_STATE_HOME/rice/active` pointer;
  `rice-switch` only validates + writes the pointer + sets wallpaper. Nix never
  writes to `$XDG_STATE_HOME`; users never edit store paths.
- `mkThemeManifest` validates the schema at build time
  ([theme-manifest](../../docs/architecture/contracts/theme-manifest.md)) —
  a broken theme must fail `nix flake check`, not the running shell.
- Propagation goes THROUGH the existing HM bridge (D-012): the active manifest
  feeds `theme.colors` / `theme.style`; waybar/hyprlock/qt/GTK modules keep
  reading the bridge. Never build a parallel second theming path.
- Reuse `modules/themes/_fmt.nix` for color format conversions.
- Derive raster assets from SVG in a derivation (D-011); never commit generated
  rasters.
- Changes here are validated by evaluating/building the affected host and
  building every enabled theme manifest.

## Forbidden

- Theme-specific conditionals scattered outside `modules/rice/themes/<name>/`.
- Hardcoding theme values in feature modules — everything flows from the
  manifest.
- Coupling anything outside `modules/rice/` to its internals; external access
  is via `rice.*` options only.
- Making live switching depend on a rebuild, or rebuild correctness depend on
  mutable state.

## Checklist

- [ ] Options under `rice.*`; module named per repo convention.
- [ ] All enabled themes still build; host eval passes.
- [ ] Bridge-fed propagation only; no duplicate token definitions.
- [ ] Store/state boundary respected (Nix → store, user → XDG state).

## Pointers

[theme-manifest](../../docs/architecture/contracts/theme-manifest.md) ·
[ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md) ·
[DECISIONS.md](../../docs/architecture/DECISIONS.md) (D-003, D-011, D-012) ·
`nix-module-quality.md`
