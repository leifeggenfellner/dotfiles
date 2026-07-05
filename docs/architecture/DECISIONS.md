# Rice Framework — Decisions Log

Canonical, append-only record of architectural decisions for the rice framework.

Rules for this file:

- Entries are numbered (`D-NNN`), dated, and never edited after landing. To change a
  decision, append a new entry and set the old one's status to `superseded by D-NNN`.
- Any change that breaks a contract in `contracts/` must land in the same commit as a
  new entry here.
- If a proposed change conflicts with an active entry, the conflict must be named and
  resolved explicitly — never silently redirected.

Status values: `active` | `superseded by D-NNN`.

---

## Decisions

### D-001 — Two-tier knowledge system (Law / Practice)

- Date: 2026-07-03 · Status: active
- The project knowledge system has two tiers. **Law** lives in `docs/architecture/`
  (ARCHITECTURE.md map, this decisions log, ROADMAP.md, `contracts/`). **Practice**
  lives in `.claude/skills/` as small rule-skills that link back to Law and never
  restate contracts. This supersedes the previous split system across `.claude/skills/`
  and `.github/ai/`, whose still-valid content was migrated here (see Legacy imports).
- Why: two overlapping doc trees had already begun to drift; contracts must be
  single-sourced while task guidance stays short and disposable.

### D-002 — DECISIONS.md is the single decision log

- Date: 2026-07-03 · Status: active
- All agreed architectural decisions land in this file or they are not decisions.
  Later ideas that conflict must cite and supersede the relevant entry.

### D-003 — Theme switching is a two-layer hybrid

- Date: 2026-07-03 · Status: active
- Nix builds **all enabled themes** into the store and writes an index. A mutable
  pointer at `$XDG_STATE_HOME/rice/active` selects the active theme; the shell,
  wallpaper, and lockscreen-adjacent surfaces switch live (<1s). GTK/Qt/cursor/icons/
  fonts follow the Nix-default theme at rebuild. Home Manager specialisations for
  full live fidelity are deferred (see ROADMAP).
- Why: rebuild-only kills the rice-switcher UX (minutes + sudo); specialisations
  multiply eval/build cost per theme. Hybrid gets most of the experience with one
  trivially debuggable state file.

### D-004 — Themes are data first; plugins are the escape hatch

- Date: 2026-07-03 · Status: active
- Themes provide tokens, assets, and widget configuration. They MAY ship
  self-contained plugin widgets/effects implementing the public widget contract.
  They may NEVER replace or patch runtime internals. Customization tiers, in order
  of preference: tokens → widget `settings` → delegate slots → plugin widgets.
- Why: full-override theming has no stable contract; every runtime refactor would
  break every theme.

### D-005 — Token schema: closed core, open edges

- Date: 2026-07-03 · Status: active
- `tokens.*` is a fixed semantic schema every theme must fill (runtime relies on it).
  `palette.*` and `widgets.<id>.settings` are open-ended, namespaced per theme.
- Why: the runtime needs guarantees; themes need expressiveness. Splitting the schema
  gives both without forcing all themes into one content model.

### D-006 — Runtime contains zero theme knowledge

- Date: 2026-07-03 · Status: active
- No theme-name literals, theme asset catalogs, or theme-flavored identifiers under
  `runtime/`. The LOTM pathway catalog moves out of `ThemeLoader.qml` into the LOTM
  theme package. Components get theme-neutral names (Sigil→IconButton, Plate→Panel,
  Chip→Pill, Dial→Gauge, RitualClock→ClockWidget, Pathways→WorkspaceIndicator).
  Theme flavor returns via tokens, fonts, assets, and plugins — never identifiers.

### D-007 — Runtime location and layering

- Date: 2026-07-03 · Status: active
- The Quickshell runtime moves to `modules/rice/runtime/quickshell/` with layers
  `utils / core / components / widgets / modules / services`. Import rules are
  defined in ARCHITECTURE.md and mechanically enforced by `scripts/rice-lint.sh`
  wired into `nix flake check`.

### D-008 — Services prefer native APIs and DBus over CLI polling

- Date: 2026-07-03 · Status: active
- Use Quickshell native services (Pipewire, Mpris, UPower, Notifications, SystemTray)
  and DBus (NetworkManager, BlueZ) where available. CLI `Process` calls are a last
  resort and must be event-triggered rather than timer-polled where possible; any
  remaining poll must justify its interval in-code. Existing polling services migrate
  opportunistically, not big-bang.

### D-009 — Widgets receive services by injection

- Date: 2026-07-03 · Status: active
- A widget declares service dependencies in its descriptor (`services: [...]`);
  the mount resolves and passes the singletons as properties. Widgets never import
  services. This is the concrete mechanism for the pre-existing "no widget imports
  services" rule (L-010).

### D-010 — Motion is centralized and state-driven

- Date: 2026-07-03 · Status: active
- A `Motion` singleton exposes semantic animations resolved from theme motion tokens;
  no inline durations or curves in UI code. Animation is state-driven only, with one
  governed exception: a budgeted **ambient tier** themes can opt into
  (`tokens.motion.ambient`), subject to the global reduce-motion flag and the effect
  tiers T0/T1/T2 defined in `contracts/motion-contract.md`.

### D-011 — Assets are addressed by semantic role

- Date: 2026-07-03 · Status: active
- The runtime asks `Theme.assets` for roles (e.g. `logo`, `wallpapers`), never
  filenames. Raster icon variants are derived from SVG sources by a Nix derivation
  at build time, not hand-maintained.

### D-012 — Rice manifest is upstream of the legacy theme bridge

- Date: 2026-07-03 · Status: active
- When `rice.enable`, the active theme manifest feeds the existing Home Manager
  `theme.colors` / `theme.style` bridge, so GTK/Qt/waybar/hyprlock keep working with
  zero duplication. There is no parallel second theming path.

### D-013 — Contracts are versioned with a deprecation cycle

- Date: 2026-07-03 · Status: active
- The manifest carries `schemaVersion`; widget descriptors carry `contractVersion`.
  The runtime warns (never crashes) on older-but-supported versions. Breaking either
  requires a decision entry here plus a migration note in ROADMAP.md; removed fields
  are aliased in the loader for one migration cycle.

### D-014 — Vertical-slice execution order

- Date: 2026-07-03 · Status: active
- The framework is built LOTM-first as a vertical slice that forces the framework
  to emerge; generalization happens by extraction from working code, never by
  speculation. Concretely: a greenfield runtime skeleton is built directly at the
  D-007 target location (`modules/rice/runtime/quickshell/`) with mock services;
  the existing bar (`modules/programs/quickshell/ui/`) keeps running untouched
  until the new shell reaches parity, then retires (generalization pass).
  Interim waiver: `core/Theme.qml` holds static token values until the theme
  system phase; L-004 still binds all UI code (widgets read `Theme.*` only).
  The lockscreen remains hyprlock; no Quickshell lock layer is planned.
  This re-sequences ROADMAP.md (generalization moves behind the slice) without
  superseding D-006/D-007, which remain the end-state.

### D-015 — Skills declare direction of authority; contracts enforced from day one

- Date: 2026-07-03 · Status: active
- Every rice skill carries an `Authority` block — **Controls** (final say),
  **Reads** (may depend on, never redefine), **May not influence** (must defer;
  wanting change there is a contract-change proposal, not a skill matter) — with
  a consolidated matrix in ARCHITECTURE.md where no two skills' Controls overlap.
  Contracts are enforced mechanically from the first day of the greenfield tree:
  `scripts/rice-lint.sh` (per-layer import allowlist + theme-literal ban) runs in
  `nix flake check`; the legacy tree is exempt until it retires.
- Why: skills previously bounded what they *contain*, not what they *influence*,
  leaving room for bidirectional coupling (e.g. widget guidance quietly defining
  service expectations); and unenforced contracts drift.

### D-016 — Semantic icon system

- Date: 2026-07-03 · Status: active
- UI code never hardcodes icon glyphs; it references semantic icon names through
  `Theme.icon(name)` / the `Icon` component. The runtime ships a theme-neutral
  default map (Nerd Font glyphs); a theme's manifest (`assets.icons`) may remap
  any name to a different glyph or to an image file relative to its assets root
  (values containing "/" are files). Unknown names resolve to a visible
  placeholder, never an error.
- Also recorded here: the manifest source file is named `_theme.nix` (not
  `theme.nix` as the contract originally read) — the underscore prefix keeps
  import-tree from loading theme data as a flake-parts module. Contract text
  updated in the same commit (D-013 procedure).

### D-017 — Authored artwork is source, not a derived variant

- Date: 2026-07-04 · Status: active
- D-011 (build-time rasterization, no hand-maintained derived variants) applies
  only to assets genuinely derivable from another source. The LOTM
  `pathways_png/` set was misclassified as derived: it is separately authored
  color artwork (glowing emblems), while the SVGs are black-silhouette traces —
  different artworks sharing names. Authored color art is a first-class theme
  asset (like wallpapers) and may carry baked-in color; L-005 (color from
  tokens, not images) governs UI effects and token-styled elements, not
  authored art. The raster pipeline remains for true silhouette/derivable
  cases.

---

## Legacy imports

Migrated 2026-07-03 from `.github/ai/plans/arcanum-bar/decisions.md` (now deleted).
All remain active unless marked otherwise.

- **L-001** Bar (and all multi-widget surfaces) are descriptor-driven, never hardcoded.
- **L-002** Only one popout exists at a time; popouts are anchored to their origin
  widget, never floating.
- **L-003** Services own state; UI never owns system state. Components are strictly
  presentation-only.
- **L-004** No hardcoded colors or spacing in QML; the theme system is token-based.
- **L-005** Glow/accent effects derive from tokens, not baked into images.
- **L-006** Max 3 accent colors visible simultaneously.
- **L-007** Animation only on state change (generalized by D-010's ambient tier).
- **L-008** Hyprland config stays Nix-generated. Lua is an optional behavior layer
  only, never a config replacement.
- **L-009** System cluster replaces a standalone systray; tray items are allowlisted.
- **L-010** Widgets expose the descriptor contract and never import services
  (mechanism defined by D-009).
- **L-011** Clock keeps digits alongside the dial. Default bar height 56px,
  configurable per theme.
- **Rejected ideas** (do not re-litigate without a superseding entry): full Hyprland
  Lua rewrite; permanently animated UI elements; full systray exposure in the bar;
  per-widget independent floating popouts.
