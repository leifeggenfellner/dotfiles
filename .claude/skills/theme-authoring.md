# Skill: Theme Authoring

## Scope

Creating or modifying a theme package under `modules/rice/themes/<name>/`:
manifest (`theme.nix`), tokens, assets, widget configuration, plugin packaging.

## Authority

- **Controls:** the contents of a theme package — tokens, assets, settings,
  plugin packaging.
- **Reads:** theme-manifest and widget contracts.
- **May not influence:** runtime structure, widget internals, service behavior —
  including indirectly via layout assumptions baked into settings. If the
  manifest can't express a need, that's a contract-change proposal.

## Rules

- The manifest is the theme's ONLY interface to the runtime. Follow
  [contracts/theme-manifest.md](../../docs/architecture/contracts/theme-manifest.md)
  exactly; the schema is closed-core / open-edges (D-005):
  fill every `tokens.*` key; put theme-specific extras under `palette.*`,
  `assets.art.*`, and `widgets.<id>.settings`.
- Assets are organized by role (`wallpapers/`, `icons/`, `art/`, `sounds/`),
  `snake_case` filenames. `assets/preview.png` is optional — the index build
  derives a token-swatch preview when absent (D-018). Raster variants are
  derived from SVG by the build, not committed by hand (D-011).
- Theme identity flows through tokens, assets, fonts, and settings — e.g. the
  workspace indicator's icon set, labels, and per-workspace colors are
  `widgets.<id>.settings`, not runtime code. Start small (a few workspace
  identities, not the whole catalog); keep icon usage semantic, prefer
  low-opacity watermarks over high-contrast overlays.
- Customization escalates through the tiers of the
  [widget contract](../../docs/architecture/contracts/widget-contract.md):
  tokens → settings → delegate slots → plugin widgets. Plugins are for
  genuinely new widgets only.
- Plugins live in `themes/<name>/widgets/`, are declared in the manifest
  `plugins` list, and may import only runtime `core/`, `components/`, `utils/`
  plus injected services.
- Validate against at least two themes: the one you changed AND one other, so
  runtime assumptions never calcify around a single theme.

## Forbidden

- Touching runtime files to make a theme work — if the manifest can't express
  it, propose a contract extension (DECISIONS entry) instead.
- Duplicating token values across files; one source per value inside the theme.
- Per-theme conditionals (`if theme == …`) anywhere outside the theme's own
  directory.
- Executable behavior in the manifest; it is pure data.

## Checklist

- [ ] Manifest validates (build succeeds; all required `tokens.*` present).
- [ ] Assets by role, preview.png present, no hand-made raster derivatives.
- [ ] No runtime edits required by this theme change.
- [ ] Second theme still renders correctly.

## Pointers

[theme-manifest](../../docs/architecture/contracts/theme-manifest.md) ·
[widget-contract](../../docs/architecture/contracts/widget-contract.md) ·
[DECISIONS.md](../../docs/architecture/DECISIONS.md) (D-004, D-005, D-006, D-011)
