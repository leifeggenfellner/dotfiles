# Rice Framework

Theme-agnostic desktop framework: Nix builds theme packages, the Quickshell
runtime renders whichever one is active. The runtime never knows about a
specific theme; themes provide data (tokens, assets, config) and optional
plugin widgets.

## Canonical documentation

The source of truth lives in [docs/architecture/](../../docs/architecture/):

- [ARCHITECTURE.md](../../docs/architecture/ARCHITECTURE.md) — layers, folder
  layout, dependency and import rules, event flow.
- [DECISIONS.md](../../docs/architecture/DECISIONS.md) — append-only decision
  log. Read this before proposing direction.
- [ROADMAP.md](../../docs/architecture/ROADMAP.md) — phased build order.
- [contracts/](../../docs/architecture/contracts/) — theme manifest, widget,
  service, and motion contracts.

Task-level rules for agents live in `.claude/skills/` (start with
`rice-architecture.md`).

## Layout

- `themes/<name>/` — theme packages (manifest, tokens, assets, optional widgets).
- `runtime/` — the Quickshell runtime (migrating here from
  `modules/programs/quickshell/`; see ROADMAP Phase 1).
- `shared/` — cross-theme fallback assets.
- `nix/` — framework Nix: options, manifest builder, switching, propagation
  (splitting out of `modules/rice.nix` as it grows).

## Selecting a theme

- `rice.enable = true;` and `rice.theme = "<name>";` in host config set the
  Nix-default theme.
- At runtime, `rice-switch <name>` flips the active theme
  live via `$XDG_STATE_HOME/rice/active`. It is a per-user transaction covering
  Hyprland visual tokens, the pointer, Quickshell reload, and wallpaper; it never
  activates a system specialisation.
- Full rebuild-time chrome remains an explicit administrator workflow through
  `/run/current-system/specialisation/rice-<name>/bin/switch-to-configuration switch`.
