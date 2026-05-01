# Rice Framework — Architecture Map

The map of the theme-agnostic desktop framework (NixOS + Home Manager + Hyprland +
Quickshell). This file is the *what*, kept short enough to read in three minutes.
The *why* lives in [DECISIONS.md](DECISIONS.md). Exact interfaces live in
[contracts/](contracts/). Build order lives in [ROADMAP.md](ROADMAP.md).

## Layers

```text
┌───────────────────────────────────────────────────────────┐
│ NIX LAYER            modules/rice/nix/ + rice.* options   │
│  theme package builder · manifest generation · index      │
│  propagation: GTK/Qt/cursor/fonts/hyprlock/wallpaper      │
└──────────────┬────────────────────────────────────────────┘
               │ builds → store paths + manifests + index
┌──────────────▼────────────────────────────────────────────┐
│ THEME PACKAGES       modules/rice/themes/<name>/          │
│  tokens · assets-by-role · widget config · QML plugins    │
└──────────────┬────────────────────────────────────────────┘
               │ selected by mutable pointer (two-layer switch, D-003)
┌──────────────▼────────────────────────────────────────────┐
│ RUNTIME (Quickshell)  modules/rice/runtime/quickshell/    │
│  core facades · components · widgets · surface modules    │
└──────────────┬────────────────────────────────────────────┘
               │ reads state / sends commands
┌──────────────▼────────────────────────────────────────────┐
│ SERVICES (UI-free singletons inside the runtime)          │
│  ← DBus, PipeWire, NetworkManager, BlueZ, Hyprland IPC    │
└───────────────────────────────────────────────────────────┘
```

The runtime is a product; themes are content packages (D-004, D-006). Coupling
between them is legal only through the
[theme manifest](contracts/theme-manifest.md) and the
[widget contract](contracts/widget-contract.md).

## Folder layout (target)

```text
modules/rice/
  nix/                    # framework Nix: options, manifest builder, switch, propagation
  runtime/quickshell/     # THE theme-agnostic app
    shell.qml             # compositor only: instantiates surfaces per monitor
    core/                 # Theme, Motion, Sound, Effects, ManifestLoader, ShellState
    components/           # primitives/ composites/ controls/ — pure presentation
    widgets/              # built-in widgets, one dir per widget, each with a descriptor
    modules/              # surfaces: bar/ launcher/ osd/ dashboard/ notifications/ …
    services/             # audio/ network/ bluetooth/ power/ mpris/ hypr/ system/ …
    utils/                # pure helpers, side-effect free
  themes/<name>/          # theme.nix (manifest source) · tokens/ · assets/ · widgets/ · preview.png
  shared/                 # cross-theme fallback assets
docs/architecture/        # Law: this map, DECISIONS, ROADMAP, contracts/
.claude/skills/           # Practice: rule-skills pointing back at Law
```

## Dependency graph (strict DAG)

```text
utils ← core ← components ← widgets ← modules ← shell.qml
utils ← services            (services import ONLY utils; never core/UI)
theme plugins → {core, components, utils} + injected services only
```

## Import rules

- `utils/` imports nothing internal.
- `services/` may import `utils/` only. No `core/`, no UI, no `Theme`.
- `core/` may import `utils/`. `ManifestLoader` is the only file that reads
  manifest JSON; `Theme` is the only facade other code reads theme data from.
- `components/` may import `core/`, `utils/`. Never services.
- `widgets/` may import `components/`, `core/`, `utils/`. Services arrive by
  injection only (D-009).
- `modules/` may import everything below it; feature wiring lives here.
- Nothing under `runtime/` may contain a theme-name literal or theme-flavored
  identifier (D-006).
- Enforced by `scripts/rice-lint.sh` in `nix flake check` (D-007).

## State categories (never mixed)

1. **System state** — owned by services; widgets read, commands go through service
   methods ([service-contract](contracts/service-contract.md)).
2. **Shell UI state** — `core/ShellState.qml`: active popout, launcher visibility,
   OSD queue, debug overlay.
3. **User prefs** — `$XDG_STATE_HOME/rice/` (active-theme pointer + `prefs.json`),
   accessed only by a `PrefsState` service. Nix defines defaults; state files hold
   user drift; nothing else is mutable.

## Event flow

- System → UI: daemon event → DBus signal/native API → service property change →
  QML bindings propagate. Property bindings are the event bus; there is no
  custom pub/sub layer.
- User → System: widget interaction → service command method → external system →
  real event returns via the same downward path. No optimistic UI state; loading
  comes from service `busy` flags.
- OSDs subscribe to service change signals with a user-initiated hint so they do
  not fire on boot-time initial reads.

## Theme switching (two-layer, D-003)

1. Nix builds every enabled theme's manifest into the store + a `themes.json` index.
2. Runtime reads `$XDG_STATE_HOME/rice/active` (fallback: Nix default) and watches it.
3. `rice-switch <theme>` validates against the index, writes the pointer, sets the
   wallpaper; the shell re-binds live.
4. GTK/Qt/cursor/icons/fonts follow at rebuild via the legacy theme bridge (D-012).

## Skill authority matrix (D-015)

Each rice skill declares direction of authority: **Controls** (final say — no two
skills' Controls overlap), **Reads** (may depend on, never redefine), **May not
influence** (must defer; wanting change there is a contract-change proposal).

| Skill | Controls | Reads | May not influence |
|---|---|---|---|
| `rice-architecture` | layer ownership, file placement, skill routing | DECISIONS, all contracts | any per-domain rule |
| `quickshell-runtime` | runtime tree layout, import direction, state-ownership placement | contracts, ARCHITECTURE | theme content, Nix option surface, widget/service internals |
| `theme-authoring` | theme package contents (tokens, assets, settings, plugin packaging) | theme-manifest + widget contracts | runtime structure, widget internals, service behavior |
| `widget-authoring` | widget internals (descriptor impl, glance/popout composition, settings schema) | widget + motion contracts, Theme/Motion facades, service state shapes | service backends/behavior, runtime layering, manifest schema |
| `service-authoring` | service internals (backends, state shape, command methods) | service contract | UI/presentation, widget structure, theme data |
| `motion-and-effects` | Motion/Sound/Effects facades, semantic animation vocabulary, tiers/budgets | motion contract, `tokens.motion` shape | token values, widget layout, service behavior |
| `rice-nix` | `rice.*` options, manifest generation, switch machinery, propagation | theme-manifest contract, repo Nix conventions | QML structure, runtime behavior, widget/service internals |

## Design principles

1. Runtime is a product; themes are content.
2. Semantic tokens only — no raw values in UI (L-004).
3. One source of truth per fact: manifest for theme data, services for system
   state, DECISIONS.md for choices.
4. Closed core, open edges (D-005).
5. State-driven motion (D-010, L-007).
6. Data down, commands up.
7. Boring core, expressive themes.
8. Additive migration — the old path keeps working until the new path is validated.
9. Everything debuggable — every dynamic fact inspectable via the debug overlay.
