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
- Why: skills previously bounded what they _contain_, not what they _influence_,
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

### D-018 — Switch machinery concretized (index, pointer, preview)

- Date: 2026-07-06 · Status: active
- The D-003 two-layer switch is realized as: `mkThemeIndex` builds EVERY theme
  under `modules/rice/themes/` and installs `~/.config/rice/themes.json`
  (`{ schemaVersion, default, themes.<name> = { displayName, manifest, preview,
wallpapers } }`, store paths). The mutable pointer `$XDG_STATE_HOME/rice/active`
  holds a theme name; it is written ONLY by `rice-switch` (atomic rename +
  wallpaper orchestration + IPC nudge `rice reload`). Runtime resolution order:
  `$RICE_MANIFEST` env → pointer via index → `~/.config/rice/manifest.json`
  (Nix-default theme).
- The pointer is read and watched by `core/ManifestLoader` — it is manifest-
  resolution input, not a user pref. This narrows the ARCHITECTURE note that
  `$XDG_STATE_HOME/rice/` is "accessed only by a PrefsState service": that rule
  now covers `prefs.json` (still future); text updated in the same commit.
- Previews: not a manifest field (contract's `meta.preview` removed before any
  theme used it, D-013 procedure). A theme MAY ship authored
  `assets/preview.png` (D-017 — authored art wins); otherwise the index build
  derives a swatch card from the theme's own tokens (D-011 — derived variants
  are built, never hand-maintained). Every index entry therefore always has a
  preview.
- Why: switching must work with zero eval at switch time (index carries
  everything `rice-switch` and the switcher UI need), and no theme should be
  blocked on producing screenshot art before it can appear in the switcher.

### D-019 — Per-theme wallpapers, prefs.json ownership

- Date: 2026-07-06 · Status: active
- Wallpapers are per-theme, build-derived: `mkThemeManifest` globs
  `themes/<name>/assets/wallpapers/` (png/jpg/jpeg/webp, natural-sorted) into
  `assets.wallpapers` as store paths sharing the assets-dir store copy. Themes
  never hand-list wallpapers; the list may be empty (contract's "required ≥1"
  amended in the same commit, D-013 procedure). The index inherits the list;
  browsing/cycling operates on the ACTIVE theme's set only.
- `$XDG_STATE_HOME/rice/prefs.json` (`{ schemaVersion, wallpapers.<theme> }`)
  is written ONLY by `services/prefs/PrefsState`. Services never import core,
  so PrefsState is theme-blind: the module-layer `WallpaperCommands` singleton
  is the single apply path — `WallpaperState.setWallpaper(path)` +
  `PrefsState.recordWallpaper(Theme.activeName, path)` in one user-initiated
  step. Observation-based recording (watching `WallpaperState.current`) was
  rejected: during a rice switch the pointer and persist-file reloads race and
  would corrupt the old theme's memory.
- `rice-switch` READS prefs.json at switch time (jq): remembered wallpaper for
  the target theme (re-matched by basename if the store path went stale), else
  `wallpapers[0]`, else keep the current wallpaper. Restoration never writes
  prefs — no feedback loop.
- Why: wallpaper identity is part of a rice; cycling across themes' sets or
  losing your pick on every switch breaks that. One writer keeps the state
  file debuggable; explicit-apply recording keeps it correct.

### D-020 — Lockscreen resolves the rice theme at lock time

- Date: 2026-07-07 · Status: active
- hyprlock.conf declares hyprlang `$rice_*` variables (12 colors + 2 fonts)
  with rebuild-time defaults from the D-012 legacy bridge; widgets reference
  variables, never literals. At lock time `lock-screen` resolves
  pointer → `themes.json` index → active manifest (same order and jq idioms
  as `rice-switch`, read-only) and rewrites only the variable-definition
  lines: `.palette.legacy.<key>` → `rgba(<hex><alpha>)`,
  `.tokens.typography.families.{display,mono}` → font families. The variable
  spec lives once in `modules/programs/_hyprlock-vars.nix`, shared by the HM
  config and the script. Absent index/pointer/manifest → defaults stand;
  non-rice hosts and direct `hyprlock` runs are unchanged.
- Lock background precedence: the theme's `assets.lockscreen[0]` (new
  optional image role, globbed at build like D-019 wallpapers — LOTM ships a
  Klein still derived from authored video; the video itself is not a repo
  asset since nothing in the stack renders video) → live wallpaper persist
  file → baked default.
- Scoping note on D-018: "ManifestLoader is the only pointer reader/watcher"
  describes the QML runtime. Shell tools (`rice-switch`, `lock-screen`) are
  invocation-time read-only consumers of pointer + index — never writers
  (except rice-switch on the pointer), never watchers.
- D-003's lockscreen clause is delivered lazily: the theme resolves at the
  next lock, which is the first moment it is visible.
- Also recorded: the script's original monitor/wallpaper seds matched
  `key = value` while HM's `toHyprconf` emits `key=value` — both were silent
  no-ops (the lockscreen never followed the live wallpaper). Patterns are now
  whitespace-tolerant EREs anchored on the key.

### D-021 — Ambient effects engine (tokens.effects + governor)

- Date: 2026-07-07 · Status: active
- The motion contract's ambient tier (T1) is realized as: an optional
  closed-core `tokens.effects = { layers = [ { type; tint; opacity; … } ]; }`
  block (validated at build; layer types v1: `fog`, `particles`, `vignette`;
  tints are color TOKEN REFS like `"accent.primary"`, never literals — L-005).
  Theme-neutral primitives live in `components/effects/`; `core/Effects.qml`
  is the sole reader of the config and enforces budgets STRUCTURALLY
  (≤ 4 layers, ≤ 12 particles, opacity caps) — what it does not emit cannot
  render. Rendering happens in a per-monitor `modules/ambient/AmbientLayer`
  (layer-shell Bottom, input-transparent, unmapped + unloaded when off, so
  ambient-off steady state costs exactly zero).
- The run/pause policy lives in ONE place: `modules/ambient/AmbientController`
  composes PrefsState (reduce-motion, ambient mode `auto|off`) + PowerState
  (on battery ⇒ pause) + HyprState (any fullscreen toplevel ⇒ pause) and
  pushes verdicts onto `ShellState.ambientActive` / `ShellState.reduceMotion`.
  This bridge exists because core/components may not import services; effect
  primitives bind ShellState only.
- prefs.json (D-019 file, same sole-writer rule) gains an additive `motion`
  block: `{ reduce: bool, ambient: "auto"|"off" }`.
- Why: atmosphere is the point of a rice, but D-006 forbids theming the
  runtime and rule-of-import forbids effects reading system state; data-driven
  neutral primitives + a single modules-layer governor give themes expressive
  ambience while keeping the runtime boring, budgeted, and pausable.

### D-022 — Motion v2: manifest easings honored, ceremonial, reduce-motion

- Date: 2026-07-07 · Status: active · Narrowed by D-070 (the rail's turning and sweeping moments fade under reduce-motion)
- The manifest's named easing curves (`tokens.motion.easings`, declared in the
  contract since v1 but silently ignored — Theme hardcoded enums) are now
  resolved by `Theme` from curve-name strings, warn-and-default (OutCubic) on
  unknown names. Optional `tokens.motion.durations.ceremonial` is added for
  infrequent, deliberate moments (power menu, theme switch); it defaults to
  `slow` so undeclaring themes keep one tempo. Both changes are additive —
  schemaVersion stays 2.
- The motion contract's global reduce-motion flag is concretized:
  `PrefsState.reduceMotion` → pushed onto `ShellState.reduceMotion` by the
  D-021 governor → folded into `Motion.enabled`, so every animation collapses
  to instant through the existing spec mechanism.
- Vocabulary: `awaken` joins (one-shot startup reveal of surface contents).
  The motion vocabulary continues to grow only when a surface needs a name
  (D-014 anti-speculation) — the LoTM plan's remaining names land with their
  consuming phases, not ahead of them.

### D-023 — Surface settings share the widget config namespace

- Date: 2026-07-07 · Status: active
- Built-in surfaces that need theme-provided labels or small content settings
  read them through the existing `Theme.widgetConfig(surfaceId).settings` path,
  using the manifest's `widgets.<id>` namespace. Phase 14 first applies this to
  `widgets.launcher.settings` (`placeholder`, `epigraphs`, result layout), so
  the launcher can become the Summoning for LOTM while remaining a plain app
  launcher for themes that provide no surface settings.
- This is a clarification, not a new contract surface: widget ids and surface ids
  share one flat id namespace, settings remain open-ended and owner-defined, and
  runtime core still never reads theme-specific keys. Themes without a matching
  entry receive the surface's neutral defaults.
- Why: surfaces sometimes need the same tier-2 content customization as widgets,
  but a parallel `surfaces.*` manifest tree would duplicate machinery and invite
  split ownership.

### D-024 — Sound, media, and correspondence remain event-bound

- Date: 2026-07-07 · Status: active
- Theme sounds are assets, not tokens: `assets.sounds.<event>` maps a semantic
  event name to a theme asset path, resolved only through `Theme.soundUrl()`.
  `core/Sound.qml` is a theme-neutral facade that plays semantic events via the
  Nix-owned `rice-sound-play` command. Sounds default muted through
  `PrefsState.sound.muted`; the modules-layer `SoundController` bridges that
  durable pref onto `ShellState.soundMuted` so core never imports services.
- Sound may fire only from user-visible, user-driven event edges. Notification
  sounds are emitted by the toast surface after a toast is appended; DND or any
  suppressed visual means no sound. Background state loads, boot hydration,
  timers, and ambient effects never play sound.
- Media controls use Quickshell's native MPRIS service (D-008 tier 1) wrapped by
  `services/mpris/MprisState`; widgets receive it by descriptor injection
  (D-009). The built-in `media` widget is the Gramophone: metadata, progress,
  previous/play-next controls, no player-specific UI state.
- Notification parity is completed in the Quickshell path: `NotificationState`
  exposes actions, inline reply metadata, images/urgency, and command methods;
  Correspondence UI renders urgency styling, actions, replies, dismiss/clear,
  and a durable `PrefsState.notifications.dnd` flag bridged into `ShellState`.
- Why: audio is part of the desktop atmosphere, but it is intrusive by default.
  Keeping sound event-bound, muted until explicitly enabled, and visually
  twinned preserves the rice fantasy without creating hidden background noise or
  a theme-specific runtime path.

### D-025 — Prefs extras and the Artifact Satchel

- Date: 2026-07-07 · Status: active
- `$XDG_STATE_HOME/rice/prefs.json` gains an additive `extras` namespace:
  `extras.<namespace>.<key> = value`. `PrefsState.extra(namespace, key,
fallback)` and `PrefsState.setExtra(namespace, key, value)` are the only
  runtime API. The D-019 sole-writer rule remains unchanged: PrefsState writes
  prefs, modules/surfaces request namespaced changes, and services never persist
  state directly.
- Namespaces are owner-defined and must be stable surface/plugin ids. Extras are
  for durable user drift that is not system state and not theme data: pinned
  clipboard entries, daily tarot draw state, dismissed flavor hints, and similar
  small preferences. They are not a database, not an IPC bus, and not a place for
  service caches.
- The first consumer is the Artifact Satchel. `services/clipboard/ClipboardState`
  wraps `cliphist` with event-triggered commands (`list`, `decode | wl-copy`,
  `delete`), while Hyprland owns the long-lived `wl-paste --watch cliphist
store` process. The Satchel surface opens on demand, refreshes history, copies
  on activation, and records sealed/pinned entries in `extras.satchel.sealed`.
- Why: the plugin contract needs a small durable namespace soon, but adding ad hoc
  files per surface would erode the state model. A generic extras bucket keeps
  persistence debuggable and still forces every owner to stay in its namespace.

### D-026 — Delegate slots stay logic-neutral

- Date: 2026-07-08 · Status: active
- A built-in widget may expose a small named delegate slot through
  `widgets.<id>.settings` when tokens/settings cannot express the desired visual
  shape but a plugin would be too much authority. Delegate slots are owned by the
  built-in: the runtime selects from known delegate names, keeps the same service
  injection and command methods, and preserves the default delegate for themes
  that configure nothing.
- The first real tier-3 use is the power widget. `widgets.power.settings.delegate
= "radial"` swaps the default linear menu for a radial ritual layout, but every
  action still calls the same injected `SessionState` commands (`lock`, `logout`,
  `reboot`, `poweroff`). LOTM supplies only labels and semantic icon overrides;
  non-LOTM themes keep the linear menu unchanged.
- Phase 18 also adds divination dashboard panels as ordinary built-ins, not theme
  plugins: `WeatherState` owns weather and local moon state, while `weather` and
  `calendar` dashboard widgets render injected service data through tokens and
  widget settings.
- Why: delegate slots give themes a stronger visual dialect for existing
  workflows without letting theme data replace behavior. This keeps D-006 intact
  and saves plugins for genuinely new widgets.

### D-027 — Theme plugins are packaged directories with injected services

- Date: 2026-07-08 · Status: active
- `plugins[]` entries in a theme manifest name a stable widget id, a theme-
  relative source directory, an entry QML file, placement metadata, and service
  ids. The Nix manifest builder validates the source directory and entry file,
  then serializes the containing `modules/rice` package root as a store path so
  plugin-local assets and allowed runtime imports travel together.
- The runtime registry merges built-ins with ready plugin components from the
  active manifest. Plugins that fail to load are skipped with a warning; they do
  not take down the shell and do not affect built-in widgets. Widget mounts
  provide `theme`/`motion` facades plus only the services declared by the
  descriptor, avoiding duplicate runtime singleton imports from plugin store
  paths.
- The first plugin is LOTM `tarotDraw`, rendered in the dashboard. It receives
  `prefs`, `theme`, and `motion` by injection, persists a daily draw under
  `extras.tarotDraw.daily`, and keeps card faces/back art inside its theme plugin
  directory.
- Why: a plugin is the contract's escape hatch for genuinely new theme-specific
  widgets. Packaging the plugin as a directory keeps authored assets and QML
  together, while injected services preserve the runtime layering rules.

### D-028 — Shader tier uses runtime-owned precompiled assets

- Date: 2026-07-08 · Status: active
- T2 shader effects are runtime capabilities, not theme code. Shader source files
  live under `components/effects/shaders/`, are reviewed with the runtime, and are
  precompiled by the rice Quickshell config derivation with Qt Shader Tools
  (`qsb --qt6`) into adjacent `.qsb` assets plus a generated shader manifest.
- Themes select and parameterize shader-capable effects only through the existing
  `tokens.effects.layers` data. They never ship GLSL/QSB files, and plugin widgets
  may not load arbitrary shader code. This keeps GPU code reviewable, cached, and
  covered by Nix build failures instead of runtime surprises.
- Runtime loaders must be fail-soft. `ShaderSurface` activates only when the
  generated shader manifest says a compiled asset exists; dev runs from the repo
  and driver/runtime failures fall back to the existing T1/T0 visuals. Phase 20
  first applies this to fog and a brief ink-reveal garnish on `surfaceReveal`.
- Why: shader ambience can lower the steady-state cost of fog, but it must remain
  garnish. The desktop's legibility and the motion/reduce-motion contract are
  carried by the existing non-shader paths.

### D-029 — Idle warning is a transient ambient hint

- Date: 2026-07-09 · Status: active
- Phase 21 connects hypridle to the rice runtime through a best-effort IPC hint:
  an additive hypridle listener calls `ambient setIdleHint on` shortly before the
  primary idle timeout and `ambient setIdleHint off` on resume. The hint is raw
  session state, never a pref. `modules/ambient/AmbientController` remains the
  sole policy owner and publishes `ShellState.idleApproaching` only when the
  existing ambient gates allow it: theme motion/ambient enabled, reduce-motion
  off, ambient mode not off, and not fullscreen. Unlike continuous ambient fog,
  the short idle warning is allowed on battery because it precedes an explicit
  system idle timeout and must remain visible on laptops.
- The warning renders as per-monitor, input-transparent `rice-idle` overlay
  windows. It may use runtime-owned precompiled shaders when available and must
  keep a T1 fallback. It never samples or owns client windows, never intercepts
  input, and never replaces or delays hypridle/hyprlock behavior.
- Why: the desktop can foreshadow lock/DPMS with atmosphere, but idle authority
  belongs to hypridle and session locking belongs to hyprlock. Keeping rice to a
  cancellable hint avoids timing races and preserves ordinary input cancellation.

### D-030 — Hidden lore hooks are settings-driven flavor events

- Date: 2026-07-09 · Status: active
- Phase 22 adds experimental world events as runtime-owned flavor hooks. Themes
  may configure launcher incantation phrases, an hourly bell, a daily fog surge,
  and a calendar click secret through ordinary `widgets.*.settings` data. Runtime
  defaults keep every hook off; disabling all hook settings leaves the Phase 21
  desktop behavior unchanged.
- Hooks emit transient edges through `ShellState` (`flavorEventSerial` and
  `fogSurgeSerial`). `modules/lore/LoreController` owns clock-driven events and
  exposes path-scoped IPC for smoke tests; launcher and calendar surfaces may
  trigger the same generic flavor-event path from their own settings. The overlay
  is input-transparent and unmapped while inactive.
- Why: hidden lore should feel discoverable, but it must remain garnish. Theme
  data may provide phrases and copy; it must not install behavior code or change
  core workflows.

### D-031 — OSDs render explicit user-initiated edges

- Date: 2026-07-09 · Status: active
- Volume and brightness OSDs are not raw service-change listeners. The `osd`
  module owns a path-scoped controller IPC target for user-initiated controls
  and show hints. It mutates through services when the shell is running, and
  Hyprland bindings keep direct system-command fallbacks when it is not.
- `ShellState` carries only transient OSD UI state (`osdKind`, `osdSerial`,
  `osdVisible`). Audio and brightness values remain owned by their services, so
  boot-time service reads and external background changes do not pop the OSD.
- Why: media keys need immediate feedback, but the OSD must never become a second
  source of system truth or make volume/brightness keys depend on the shell being
  alive.

### D-032 — The dock is retired

- Date: 2026-07-09 · Status: retired 2026-07-10
- The optional dock experiment proved that `AppsState.findApp()` and
  `rowForApp()` are useful reusable app-resolution helpers, but the desktop no
  longer maps an application dock. The shell does not import or instantiate a
  dock surface, and LOTM no longer carries `widgets.dock.settings`.
- Why: the launcher is the single app-launch surface for this rice. Removing the
  dock keeps daily chrome quieter while preserving the app service helpers for
  launcher-style surfaces.

### D-033 — LOTM plugin widgets stay self-contained

- Date: 2026-07-09 · Status: active
- Additional LOTM dashboard widgets ship as theme plugins, not runtime built-ins,
  when they are specific to LOTM flavor or lore. They receive only the public
  widget injection surface: theme, motion, settings, and explicitly declared
  services. They must not import runtime internals from their packaged store path.
- Phase 25 adds a persisted `ritualLedger` plugin and a data-only
  `pathwayCompass` plugin. The ledger may use `PrefsState` through service
  injection for namespaced daily checklist state; the compass reads manifest
  settings only. Both remain ordinary dashboard descriptors registered through
  the manifest plugin list.
- Why: theme-specific widgets are the intended escape hatch from data-only
  theming, but every plugin should prove the contract instead of expanding the
  runtime API surface.

### D-034 — Theme specialisations are the full-chrome switch path

- Date: 2026-07-09 · Status: active
- The fast rice switch remains pointer-based: `rice-switch <theme>` updates the
  active theme pointer, wallpaper, and running shell without requiring root.
  Full rebuild-time chrome fidelity uses generated NixOS/Home Manager
  specialisations named `rice-<theme>`. Each specialisation forces both
  `rice.theme` and `environment.desktop.theme.scheme` to the selected theme.
- `rice.specialisations.*` controls this machinery. The theme list is derived
  from packaged rice themes by default, the prefix defaults to `rice-`, and each
  generated specialisation disables recursive specialisation generation inside
  its specialised config. `rice-switch --specialise <theme>` activates the
  matching system specialisation first, then performs the normal pointer and
  wallpaper update.
- Why: live theme switching should stay quick and user-scoped for daily play,
  while GTK/Qt/Home Manager-derived chrome needs an explicit rebuild-backed path
  when exact theme fidelity matters.

### D-035 — Theme packages may come from outside the repo

- Date: 2026-07-09 · Status: active
- Bundled themes remain the default package set, discovered under
  `modules/rice/themes/*/_theme.nix`. External theme packages join the same set
  through `rice.themes.<name>.package`, where the package root contains `_theme.nix`,
  `assets/`, and optional `widgets/`. External package names must match
  `meta.name` because manifest validation stays theme-name keyed.
- Manifest and index builders consume a shared theme package map. Plugin widgets
  are serialized as `{ source = <theme package root>; entry = <theme-relative qml>; }`,
  so bundled and external widgets use the same runtime loading path. The legacy
  color bridge resolves static palettes first, then falls back to
  `palette.legacy` from configured rice theme packages.
- Why: themes should be distributable as flakes or package roots without copying
  them into this dotfiles repo, but external packages must still pass the same
  manifest validation and runtime contract as bundled themes.

### D-036 — Tray menus remain app-native

- Date: 2026-07-09 · Status: active (tray placement amended by D-064)
- System tray items live in the system popout, never directly in the bar (L-009).
  Phase 28 exposes native StatusNotifier menus through Quickshell's tray item
  `display()` path instead of rendering DBus menu entries with custom QML.
- `TrayState` owns tray commands: activate, secondary activate, and display menu.
  The system popout maps left click to activate, right click and long-press to the
  app-native menu when present, middle click to secondary activation, and
  `onlyMenu` items to menu display on left click.
- Why: tray menus are application-owned command surfaces. Delegating menu display
  to Quickshell preserves app behavior, avoids duplicating DBus menu semantics,
  and keeps the bar free of unbounded tray chrome.

### D-037 — LOTM lockscreen uses the LOTM Quickshell variant

- Date: 2026-07-21 · Status: active
- LOTM's canonical lockscreen is the `lotm` Quickshell session-lock variant,
  selected through theme data with `assets.lockscreenVariant = "lotm"`. The
  canonical command remains `lock-screen` → `rice-lock-screen`; callers do not
  invoke variant roots directly. CLI/env overrides still win for recovery and
  debugging.
- The rice-native/default lock root remains supported as `rice-lock-screen
--variant default` and as the explicit Cyberpunk choice. This preserves the
  D-020 hyprlock-themed/default path as a recovery and non-LOTM variant instead
  of deleting it.
- The LOTM lockscreen keeps a non-locking preview root and dry-run launcher mode for smoke
  tests before any real `WlSessionLock` acquisition. Session lock failures must
  fail open where possible by releasing `WlSessionLock` before process exit.
- Supersedes the lockscreen-only clauses in D-014 and D-029 that assumed session
  locking would remain hyprlock-only. Hypridle still owns idle timing; the lock
  command owns the selected lock implementation.

### D-038 — Hyprland Lua remains Nix-generated

- Date: 2026-09-10 · Status: active
- Phase 6 makes Home Manager's `wayland.windowManager.hyprland.settings` the
  authority for the generated Lua at
  `environment.desktop.hyprland.configPath`. NixOS launch policy and Home
  Manager session state consume that same read-only path. The handwritten
  `hypr/hyprland.lua` remains an uninstalled legacy reference, not a runtime
  authority or fallback.
- Rollback is declarative: revert the Phase 6 Git changes and rebuild, or select
  a retained older Nix generation. Do not restore authority by linking or
  copying the handwritten legacy file into the active config path.
- Startup parity is behavioral, not a command-count copy of the legacy file:
  register each one-shot action under `hyprland.start`, remove parse-time and
  duplicate execution, and retain the delayed dock setup and wallpaper retry.
- Validation must be side-effect-free: render and inspect the generated source,
  make static assertions over its text, and use `luac -p` for syntax only. Do
  not execute the generated Lua or invoke a Hyprland verifier or config loader;
  loading the config may run top-level process behavior.
- Why: one Nix-owned source keeps launchers, session variables, generated
  configuration, and rollback aligned while preserving a reviewable migration
  reference. This extends L-008 without rewriting the imported decision.

### D-039 — Rice switch owns live Hyprland visual tokens

- Date: 2026-09-10 · Status: active (mapping and transport amended by D-047)
- `rice-switch` is the only installed theme-switch workflow. It validates the
  target's immutable normalized manifest, applies the mapped Hyprland visual
  keywords, atomically commits `$XDG_STATE_HOME/rice/active`, and reloads a
  running Quickshell in that order. Hyprland apply failure leaves the pointer
  unchanged; pointer or Quickshell reload failure restores the previous pointer
  and reapplies its visual tokens. A failed visual rollback reports the explicit
  recovery command `rice-hyprland-theme --active`.
- The generated `rice-hyprland-theme` adapter consumes the same normalized
  manifest as Quickshell. Its closed mapping is `accent.primary` to active
  general/group borders, `bg.surface1` to inactive general/group borders,
  `metrics.radius.medium` to rounding, and `metrics.space.{sm,md}` to inner and
  outer gaps. It rejects malformed manifests before IPC and applies no binds,
  rules, input, animation, or other behavioral configuration.
- Generated Hyprland Lua invokes `rice-hyprland-theme --active` from the
  `hyprland.start` event, after IPC is available. Lua and QML do not duplicate
  the adapter's parser: QML keeps its D-018 `ManifestLoader`, while the shell
  adapter is an invocation-time consumer like the D-020 lock command.
- The rebuild-based `theme-switcher` package and binding are retired. Its source
  remains as an uninstalled legacy reference until separate cleanup; no active
  theme path mutates Nix source or invokes `nixos-rebuild`.
- Why: Quickshell and Hyprland should present one active rice immediately without
  making mutable state a Nix source or moving behavioral Hyprland authority out
  of D-038's generated configuration.

### D-040 — Live theme switching is a user transaction

- Date: 2026-09-10 · Status: active
- `rice-switch` is exclusively a serialized per-user transaction over live
  Hyprland visual tokens, the active pointer, Quickshell reload, and wallpaper.
  It resolves its index and manifests to immutable regular Nix store files before
  effects, captures prior state, and compensates all attempted effects on failure
  or handled interruption. It reports partial rollback whenever any required
  compensation fails.
- Generated NixOS/Home Manager theme specialisations from D-034 remain available
  only through their explicit system `switch-to-configuration` paths. The
  `rice-switch --specialise` clause of D-034 is superseded; live switching never
  invokes system specialisation, rebuild, activation, or source mutation.
- Why: system activation cannot participate safely in the user-owned live-theme
  rollback boundary. Keeping it explicit avoids an irreversible side effect
  inside a transaction whose other state can be compensated immediately.

### D-041 — Monitor topology has one event-driven control plane

- Date: 2026-09-18 · Status: active
- Nix owns exact monitor identities, profile layouts, workspace assignments, and
  application routes. External displays match the exact `serial` field from
  `hyprctl monitors all -j`; descriptions are display text and never identity.
- The Home Manager `monitor-control` user service is the only runtime owner. It
  listens to Hyprland's instance event socket, coalesces monitor events with an
  event-loop timer, reconnects after socket churn, and applies output, workspace,
  and application policy through fixed-argument `hyprctl eval` calls to the
  native `hl.monitor`, `hl.workspace_rule`, and `hl.window_rule` APIs. The
  configured compositor's `keyword` request is nonfunctional, so eval
  expressions are assembled only from typed Lua literals; no runtime input is
  accepted as code. Output identifiers are validated before use. Reconciliation
  queries all outputs so a connected output disabled by one profile remains
  discoverable and can be enabled by the next, while its active-only monitor
  query determines actual enabled state. The service publishes atomic
  machine-readable status. Generated Hyprland Lua no longer launches or
  deduplicates monitor processes, superseding D-038's delayed-dock setup clause
  while retaining its Nix-generated startup authority. Legacy topology commands
  are not installed.
- `work` and `home_office` share the same two HP serials and are therefore never
  auto-distinguished. `monitor-control select <profile>` persists an explicit
  selection; `monitor-control auto` clears it. The unique family topology and
  laptop-only topology may auto-select. An ambiguous complete topology is left
  unchanged until explicit selection; an incomplete explicit topology applies
  its available outputs and assigns otherwise uncovered workspaces to the
  laptop. Unknown external outputs are left unchanged.
- Reconciliation diffs monitor geometry before applying it, binds workspaces,
  moves existing workspaces and configured application windows, then restores
  the previously focused monitor/workspace where possible. New matching windows
  follow daemon-owned dynamic rules when the pinned compositor accepts the native
  rule grammar; rule installation failure is nonfatal. State and control sockets
  are private, writes are atomic, profile names are schema-validated, and
  subprocesses always use argument vectors without a shell.
- Why: topology events and explicit user intent need one durable owner. Serial
  identity avoids duplicate-description ambiguity, while the explicit selection
  rule avoids encoding a false distinction between physically identical docks.

### D-042 — Terminal consumers read the active rice through rice-query

- Date: 2026-11-13 · Status: active (extended by D-050, D-051, D-052)
- `rice-query` is the read-only CLI adapter for shell tools that need the
  **active** theme without a rebuild. It resolves index → pointer → immutable
  manifest store file through the same resolver as `rice-hyprland-theme`
  (`modules/rice/nix/_active-manifest-lib.nix`) and exposes `active`,
  `manifest`, `get <dotted path>` (manifest) and `pref <dotted path>`
  (`prefs.json`). Exit status is the contract: 0 found, 1 not set, 2 usage or
  data error. It never writes: `PrefsState` stays the sole `prefs.json` writer
  and `rice-switch` the sole pointer writer.
- `rice-terminal` renders the theme-configured terminal surface from
  `widgets.terminal.settings` (D-023 namespace): `greeting.daily` resolves a
  daily record `{ date, id?, index? }` from a prefs path against a manifest
  catalog path (by `id`, then position), formats it with `{field}`
  placeholders, and otherwise prints `pendingLabel`; `commandNotFound.format`
  replaces fish's unknown-command line. Themes without these settings produce
  no output and exit 1, so fish falls back to its defaults. The fish greeting
  appends after other modules' greeting via `lib.mkAfter`.
- `greeting.daily.autoDraw` lets the terminal draw when no record exists for
  today (record path must be `extras.<ns>.<key>`). The terminal never writes
  prefs itself: it proposes `{ date, id, index }` over the narrow
  `prefs claimDaily <ns> <key> <json>` IPC, `PrefsState.claimDaily` stores it
  only if the stored record is not already for that date (first writer per day
  wins), and the terminal renders whatever record comes back. No running shell
  → no write, pending label. The dashboard draws through the same claim and
  offers no redraw: the daily card is fixed until the date changes.
- Theme-authored paths are the one sanctioned cross-widget read: a theme may
  point `greeting.daily.catalog` at another widget's settings (LOTM points it at
  `widgets.tarotDraw.settings.cards`). The consumer stays theme-blind; the
  theme owns the wiring. The tarot card catalog moved from plugin QML into
  those settings so the Observatory and terminal share one source, and the
  plugin now records `{ date, id, index }` (still reading the legacy `card`).
- Why: terminal flavour must follow `rice-switch` like the shell does, without
  each tool re-implementing pointer resolution or duplicating theme copy.

### D-043 — Window inspector is an on-demand overlay over a held service

- Date: 2026-11-13 · Status: active
- `services/windows/WindowStatsState` lists visible windows (active or open
  special workspace per monitor; only the fullscreen window when one is
  shown) joined with CPU % (of one core) and RSS summed over each window's
  process subtree. Backend is one short probe per tick (`hyprctl -j clients`,
  `hyprctl -j monitors`, `/proc/*/stat`) — D-008 tier 4, because per-process
  counters have no event source and Quickshell's `lastIpcObject` refresh is
  asynchronous with no completion signal, so geometry and counters would come
  from different instants. Updates run only while a consumer holds them
  (`acquireUpdates`/`releaseUpdates`); release drops CPU baselines.
- `modules/inspector`: `InspectorController` owns the `inspector` IPC target
  (`open|close|toggle|status`) and holds the service while
  `ShellState.inspectorVisible` is set; `InspectorOverlay` is a per-monitor,
  input-transparent Overlay-layer surface loaded only while requested. Hidden
  costs nothing: no timer, no process, no mapped layer.
- Themes dress it through `widgets.inspector.settings` (title, subtitle,
  `labels.{cpu,memory,processes,workspace}`, thresholds, tint). Labels are
  prefixed to the plain metric and real value, never substituted. Aura colour
  uses tokens only (accent.primary → state.warn → state.danger); motion is
  the reveal/conceal fade and value-change colour easing, so reduce-motion
  leaves a static overlay.
- Hold-to-show is a Hyprland press bind (`open`) plus a `release = true` bind
  (`close`) on Super+I; Super+Shift+I toggles. Releasing Super before I can
  miss the release bind; pressing Super+I again clears it. IPC function names
  avoid quickshell's `ipc` subcommands (`show` is one).
- Why: an inspector needs live per-process numbers, which only polling can
  provide, so the design makes polling strictly user-held and the surface
  strictly passive.

### D-044 — Boot splash and console palette are rebuild-time theme surfaces

- Date: 2026-11-13 · Status: active (ring progress replaced by D-077)
- NixOS module `rice-boot` (`modules/rice/nix/boot.nix`) dresses what runs
  before the desktop from the **configured** `rice.theme`. Each
  specialisation re-evaluates it, so every boot entry carries its own splash
  (initrd) and palette (kernel parameters). Neither can follow `rice-switch`:
  the pointer is user state and does not exist before login.
- Boot splash: themes opt in with `integration.boot = { sigil; promptLabel?;
  font?; }` in `_theme.nix` (the rebuild-time `integration` block, D-012).
  Paths are Nix paths, validated by `mkThemeManifest` (closed keys, `.svg`
  sigil, `.ttf`/`.otf` font, existence), and stripped from the runtime
  manifest JSON. `_plymouth-theme.nix` builds a Plymouth script theme
  `rice-<theme>`: the sigil recoloured to `accent.primary` with a glow, fog
  banks in `accent.secondary`, a 60-frame ink ring (turbulence-displaced SVG
  arcs rendered by resvg) that eases toward boot progress, and a vertical
  `bg.sunken` → `bg.base` gradient. All images are generated at build; the
  theme supplies only the sigil.
- Prompts: passphrase and question callbacks show the theme's `promptLabel`
  above systemd's real prompt text, then one bullet per typed character
  (or the typed answer); messages (fsck, notices) sit at the bottom in
  `fg.muted`. Themes without `integration.boot` keep the host's splash
  (`hardware-base` sets `nixos-bgrt` with `mkDefault`).
- Layout and modes (amended 2026-11-19 after the first real boot): the
  script lays out again whenever the window size changes, since a GPU
  driver that loads mid-splash replaces the firmware framebuffer under it.
  Hosts should still load their KMS driver in the initrd (shitbox: `i915`)
  so the splash never changes display. Shutdown and reboot get no progress
  from Plymouth, so there the ring starts full and drains on the script's
  clock without ever emptying. Progress comes from
  `/var/lib/plymouth/boot-duration`, which impermanent hosts persist.
- Console: `console.colors` comes from `palette.legacy` for every rice theme
  (`_console-palette.nix`): 0 crust (background), 1–6 red/green/yellow/blue/
  mauve/teal, 7 subtext1 (default foreground), 8 overlay0, 9–14 the normal
  colours lightened 30% toward white, 15 text. The `rice-boot` flake check
  enforces contrast against colour 0 (≥7:1 for 7/15, ≥3:1 for colours,
  ≥2.5:1 for the dim 8) and builds each opted-in splash.
- Recovery: the splash never blocks unlock. Typed input reaches
  `systemd-ask-password` even if the script fails to draw, other boot
  entries (e.g. `rice-cyberpunk`) use the stock splash, and the
  systemd-boot editor (`e`) accepts `plymouth.enable=0` for a text boot.
- Why: the first and last thing a machine shows should already belong to the
  theme, and both surfaces are cheap, static, and fully known at rebuild.

### D-045 — Workspace moods are derived from the active workspace

- Date: 2026-11-16 · Status: active
- A theme may give a named workspace a mood in
  `widgets.mood.settings.workspaces.<name>`: `effects` (an ambient layer list,
  same schema and budgets as `tokens.effects.layers`), `backdrop` (assets-root
  path), `veil` (`{ tint, wash ≤ 0.6, density ≤ 0.9 }`: a flat tint wash and a
  rolling fog sea drawn on the backdrop surface only), `title` (caption beside
  the real workspace name), `dnd`, and `sound` (semantic event on entering).
  Hyprland gains a theme-neutral named workspace `focus` on Super+0
  (Super+Shift+0 moves a window there) with wider gaps so the backdrop shows.
- The veil may exceed the ambient opacity caps because it covers only the
  backdrop, beneath every window, on a workspace the user chose to enter; the
  caps protect readability of the ordinary desktop. Its fog drifts only while
  ambient is active and otherwise holds still (T0 degradation).
- `HyprState.activeWorkspaceNames` (event-driven, per screen) feeds
  `modules/mood/MoodController`, the only reader of the mood settings. It
  resolves layers through `Effects.resolve` and pushes plain data onto
  `ShellState.moods`; core never reads the settings (contract rule 1).
- Moods are derived and never written anywhere: effective DND is
  `PrefsState.doNotDisturb || ShellState.moodQuiet`, and `AmbientLayer`
  renders the mood's layers instead of the theme's on that screen. Leaving the
  workspace, or restarting the shell inside it, therefore restores DND and
  ambient exactly. Battery, fullscreen, and reduce-motion gates stay with
  `AmbientController`; the static backdrop (`MoodBackdrop`, Background layer,
  input-transparent, loaded only while shown) ignores the battery gate. The
  entry sound fires only on a workspace edge after startup settles (D-024).
- A named workspace, not a special one: Hyprland draws special workspaces over
  the regular workspace's windows, and layer-shell surfaces sit below all
  windows, so a backdrop or fog could only show in the gaps.
- Why: a focus mode is a place the user goes, so its state should follow
  where the user is rather than be toggled and later undone; deriving it
  makes "restore exactly" true by construction.

### D-046 — Sky conditions drive conditional effect presets

- Date: 2026-11-16 · Status: active
- `modules/sky/SkyController` is the one place the runtime decides the sky
  conditions `fullMoon`, `rain`, and `fog`, pushed onto
  `ShellState.skyConditions`. `fullMoon` comes from the local lunar
  calculation (within the largest `window` any fullMoon preset declares,
  default 1.5 days) and needs no network. `rain`/`fog` come from
  `WeatherState.kind` (wttr.in weather code), read only when a preset keys
  on weather, so themes without one never start the probe; no weather means
  neither condition. IPC `sky setMoon|setWeather|status` overrides for smoke
  tests (not persisted).
- `tokens.effects.presets` (additive; schemaVersion stays 2): `{ when; window;
  tints; strength; layers }`. While `when` holds, `core/Effects.resolve`
  appends the preset's layers before the 4-layer budget, replaces tints by
  layer type (token refs, L-005), and multiplies opacity by layer type before
  the caps. Mood layers (D-045) go through the same resolver.
- New layer type `rain`: two pre-painted streak textures scrolling (T1,
  transform-only steady state); `count` is streak density per texture
  (10–120), not live particles, so it is outside the particle budget.
- Surface copy keys on the same names: `epigraph.settings.skyLines.<c>`
  replaces the epigraph lines, `calendar.settings.skyLabels.<c> = { text,
  tint }` replaces the moon label; the real phase and illumination stay
  beneath it.
- Weather source: the host option `rice.weather.location = { name; latitude;
  longitude; }` (exported by `rice-shell` as `RICE_WEATHER_*`) switches
  `WeatherState` to MET Norway's locationforecast for that point, with an
  identifying User-Agent as MET's terms require; feels-like is a wind chill
  since MET has none. Unset keeps wttr.in's IP guess. Added because wttr.in
  named shitbox's Tromsø area "Guleng" and reported sun under cloud.
- Why: the desktop reacting to the real sky is atmosphere the user did not
  have to ask for, so it must stay cheap (one hourly probe, only if used),
  offline-safe, and inside the budgets the ambient tier already enforces.

### D-047 — The Hyprland adapter speaks Lua and carries theme window motion

- Date: 2026-11-16 · Status: active (extended by D-048, D-049; rounding
  mapped by D-072) · Amends D-039
- Transport: Hyprland 0.56's Lua config has no `keyword` request, so the
  D-039 adapter had silently applied nothing since the Lua migration.
  `rice-hyprland-theme` now emits one Lua chunk for `hyprctl eval`, which
  exits non-zero with the Lua error on failure, so `rice-switch`'s rollback
  (D-040) still holds. Generated Lua also runs the adapter on
  `config.reloaded`, since a reload (every rebuild) drops live values.
- Mapping (closed): `accent.primary` → active general/group borders,
  `bg.elevated` → inactive borders (what the generated config already
  shows), `animations.enabled`, and compositor motion. Rounding and gaps
  leave the mapping and stay with the generated Hyprland config, so fixing
  the transport does not reshape windows.
- `tokens.motion.compositor` (optional; schemaVersion stays 2) names styles
  only — `windowsIn`/`windowsOut` (`slide|gnomed|popin N%`), `workspaces`
  (`slide|slidevert|fade|slidefade[vert] N%`), `layers` (`slide|fade|popin
  N%`). Speeds and curves derive from the theme's motion tokens: windows and
  fade in on `slow`/`enter`, out on `base`/`exit` (fade out on `fast`),
  moves and workspaces on `base`/`standard`, layers on `base`/`enter` and
  `fast`/`exit`. Qt easing names map to cubic beziers (`rice_*` curves);
  Elastic/Bounce use their Back neighbour.
- Every apply first re-emits the overridable leaves from
  `modules/programs/hyprland/_animations.nix` (shared with the generated
  config), so a theme without the block restores the baseline exactly.
- Reduce-motion (pref) or `tokens.motion.enabled = false` sets
  `animations.enabled = false`. The shell re-runs the adapter when the pref
  changes, passing the new value (`RICE_REDUCE_MOTION`) since prefs.json may
  not be written yet.
- Why: window motion is the most visible part of a theme's tempo, and the
  existing transactional switch is the right owner; keeping geometry out of
  it preserves the look the user has, which the broken adapter had never
  changed.

### D-048 — Theme cursors are built from SVG and switched live

- Date: 2026-11-16 · Status: active · Extends D-012 and D-047
- `integration.cursor = { name; size; shapes?; }`. `shapes` maps CSS /
  cursor-shape-v1 names (`default pointer text wait ns-resize ew-resize
  move` required; `progress nwse-resize nesw-resize crosshair not-allowed`
  optional) to `{ svg; hotspot = [ x y ]; }`, hotspots as fractions of the
  square SVG. `mkThemeManifest` validates it (closed keys, name pattern,
  size 8..128, known shapes, existing `.svg`, hotspots in 0..1). A cursor
  without `shapes` names an icon theme installed some other way.
- `_cursor-theme.nix` builds one icon-theme directory per theme with both
  formats: hyprcursor (scalable SVG, for Hyprland) and XCursor at 24/32/48/64
  (for XWayland and clients that draw their own cursor). The builder owns
  the alias table (`left_ptr`, `hand2`, `xterm`, `fleur`, ...); themes only
  draw. The shapes stay out of the runtime manifest; `name` and `size` stay.
- Live: `rice-hyprland-theme` runs `hyprctl setcursor` after its Lua chunk
  with the theme's cursor, or the base style's (`themes/_style.nix`) for a
  theme without one, so switching back restores it. `setcursor` answers "ok"
  even for unknown themes, so the adapter first checks that a theme cursor
  is installed in an icon directory on the XDG path, during `--check` and
  before any IPC; a missing cursor fails the switch with nothing applied.
- Every packaged theme's cursor is installed in the user profile, so any of
  them can be applied live. The rebuild-time default follows the configured
  theme: the rice bridge sets `environment.desktop.theme.style.cursorName` and
  `cursorSize` (`mkDefault`), which feed `HYPRCURSOR_THEME`, the startup
  `setcursor`, and the GTK cursor setting.
- Limitation: Hyprland draws the cursor for clients using cursor-shape-v1
  (GTK4, Qt 6, most Wayland apps), so those follow a switch at once. Clients
  that load their own cursor images (XWayland, GTK3) keep the rebuild-time
  cursor until they restart after a rebuild or specialisation switch.
- Why: the pointer is on screen more than any other theme element, and the
  existing transactional adapter already owns live Hyprland visuals, so the
  cursor joins its rollback for free.

### D-049 — Theme window chrome: gilt border gradient and group-bar cards

- Date: 2026-11-16 · Status: active · Extends D-047
- `tokens.chrome` (optional; schemaVersion stays 2): `border = { active;
  angle?; }` and `groupbar = { active?; inactive?; text?; textInactive?;
  font?; }`. Gradients are lists of 1–4 colour token refs and single
  colours are refs (L-005); `angle` is 0..359 (group-bar gradients are drawn
  at 90°); `font` names a typography family (`display|sans|mono`). Both
  `mkThemeManifest` and the adapter validate it.
- The adapter maps `border.active` to the active general and group borders
  (inactive stays `bg.elevated`) and the group-bar keys to
  `group.groupbar.col.{active,inactive}`, `text_color[_inactive]` and
  `font_family`. Every apply first re-emits the group-bar baseline from
  `programs/hyprland/_chrome.nix`, which the generated config now also sets
  (Hyprland's own defaults, made explicit), so switching away restores it.
- Motion: `tokens.motion.compositor.borderSweep = "once"` turns on
  `borderangle` with style `once` over two `slow` durations on the
  `standard` curve, so the gradient turns once when a window takes focus
  and then rests. `loop` is not accepted (L-007; permanently animated UI is
  a rejected idea). The baseline leaf, now in `_animations.nix`, keeps it
  off; reduce-motion turns all compositor animation off (D-047).
- Why: borders and group tabs are the only theme surface on every window.
  Token refs keep the gilt tied to the palette, and the once-per-focus sweep
  gives the glint without a moving UI.

### D-050 — The Starship prompt follows the active rice through per-theme configs

- Date: 2026-11-16 · Status: active · Extends D-042
- `widgets.terminal.settings.prompt` (D-023 namespace) is a closed
  vocabulary read by `modules/rice/nix/_prompt-lib.nix`: `workspace =
  { catalog; glyph?; format?; }` (catalog is a theme-authored manifest path
  to `[{ id; label; }]`, D-042's sanctioned cross-widget read; `format`
  fills `{glyph} {label} {id}`), `git.label`, and `failure.label`. Labels
  always sit beside the real value: git status keeps every flag with its
  count, the failure marker keeps the exit code and signal name, and an
  unlisted workspace shows its real name or id.
- At rebuild, every packaged theme with a prompt block gets a Starship
  config (the base `programs.starship.settings` plus the mapping) and a fish
  snippet under `~/.config/rice/prompt/<theme>.fish`. Fish asks `rice-query
  active` at startup and sources the matching snippet, which sets
  `STARSHIP_CONFIG`. A new shell therefore follows `rice-switch` without a
  rebuild; themes without the block (Cyberpunk) and shells without an
  active rice keep the base prompt.
- The workspace label is read with one `hyprctl` call when the shell starts
  and on `fish_focus_in` (a moved terminal is refocused before use), never
  per prompt: drawing the prompt costs what the base prompt costs (≈7.7 ms vs
  7.4 ms measured); startup gains ≈22 ms. Outside Hyprland it is skipped.
  A terminal moved to another workspace without being focused shows its old
  label until it is focused.
- Why: Starship has no runtime theming hook, so per-theme configs built from
  the same base are the cheapest way to change the prompt live; building
  them in Nix keeps the shell from parsing the manifest on every start.

### D-051 — Terminal tools: a live fastfetch card and rebuild-time tool themes

- Date: 2026-11-16 · Status: active · Extends D-012, D-042
- fastfetch (live): `widgets.terminal.settings.fastfetch = { title; logo?;
  labels; }` is read by `_fastfetch-lib.nix`, which builds one fastfetch
  config per packaged theme with the base greeting's rows, glyphs and values
  (user, distro, kernel, uptime, shell, mem, pkgs). Each row shows the
  diegetic label beside the plain key. `logo` is a single-colour SVG under
  the theme's `assets/`, recoloured to `accent.primary` into a 512 px PNG at
  build. Terminals that draw images show that PNG (foot/mlterm/contour via
  sixel, kitty/ghostty via the kitty protocol): chafa encodes it at greeting
  time from the terminal's cell geometry (≈20 ms, `--probe off`) and
  fastfetch places it as a raw 24×12-cell logo. fastfetch's own sixel
  encoder is not used: its output draws nothing in foot. Every other
  terminal gets the same sigil in braille. The greeting calls `__rice_fastfetch`, which prints
  the active theme's card or returns 1 so the base art and fastfetch run.
  `__rice_active` (`rice-query active`, once per interactive shell) is
  shared with the prompt (D-050).
- Tools (rebuild-time): `integration.tools` lists any of `btop bat yazi
  cava`. For the configured theme, `_tools-lib.nix` generates a btop theme
  (all 42 keys), a bat TextMate theme, a yazi theme and a cava gradient from
  its colour tokens and `palette.legacy`, through one theme-blind role
  mapping (keywords and titles `accent.primary`, functions and cached
  memory `accent.secondary`, strings `state.ok`, meters fog → gold →
  danger, and so on). The program modules set their own values with
  `mkDefault`, so a theme that does not opt in keeps them exactly.
- Why: the tools follow the rebuild-time palette like GTK/Qt (D-012); only
  the greeting needs per-theme copy at runtime, and it reuses the D-050
  pattern: build per theme, select by the active pointer.

### D-052 — Neovim follows the active rice through generated data modules

- Date: 2026-11-16 · Status: active · Extends D-042
- `widgets.terminal.settings.neovim = { colorscheme?; start?; }`, read by
  `_neovim-lib.nix`. `colorscheme = true` maps the theme's colour tokens and
  `palette.legacy` to ~120 highlight groups (UI, syntax, Treesitter, LSP,
  diagnostics, diff, Telescope) through one theme-blind table. Red
  (`state.danger`) is reserved for errors and deletions (L-006). `start =
  { title; epigraphs; recentLabel?; }` takes epigraphs as a list or as a
  theme-authored manifest path (D-042's cross-widget read).
- Each packaged theme with the block becomes a pure-data Lua module
  (`lua/rice/themes/<theme>.lua`, `lib.generators.toLua`). The theme-blind
  loader (`modules/rice/nvim/rice/init.lua`) asks `rice-query active` at
  startup (≈8 ms) and loads the matching module. A new editor therefore
  follows `rice-switch` without a rebuild; no module, no rice, or any error
  leaves the editor as `programs/neovim.nix` configures it.
- The start screen (`rice/start.lua`, no plugin) shows only when Neovim
  starts with nothing to edit: the title, one epigraph per day, and up to
  nine recent files with their real paths behind `[1]`–`[9]`, plus `[e]`
  new file and `[q]` quit. Normal background stays transparent, as before.
- Why: the editor is opened from many terminals and should match the
  active theme like the prompt does; generating data modules keeps the
  runtime Lua small and theme-blind.

### D-053 — A once-per-login session awakening

- Date: 2026-11-16 · Status: active · Extends D-022, D-024, D-030
- `widgets.awakening.settings = { title; subtitle?; hold?; lift?; sound?; }`
  opts a theme in; no `title`, no ritual (instant, as before). `hold`
  (0–3000 ms, default 900) is how long the fog holds; `lift` (300–5000 ms,
  default 2400) is how long it takes to rise away.
- `modules/awakening/AwakeningController` decides once per shell start,
  after prefs and manifest are read. A marker in `$XDG_RUNTIME_DIR` keyed by
  `HYPRLAND_INSTANCE_SIGNATURE` makes it once per login: `rice-shell`
  restarts and rebuild restarts run inside the same Hyprland instance and
  find the marker. The marker is written even when the theme has no ritual,
  so a mid-session theme switch never plays one late.
- `AwakeningOverlay` (one per screen, Overlay layer) opens veiled in
  `bg.sunken` with a full-band fog, fades in the title and subtitle beside
  the real user and time, holds, then lifts: the veil fades, the fog rises
  and thins. Its input region is empty and it takes no keyboard focus, so
  the session is usable from the first frame; it unloads when done.
- Reduce-motion (or `motion.enabled = false`) collapses it to nothing. The
  optional sound goes through `core/Sound`, so it stays muted by default.
- IPC: `quickshell -c rice ipc call awakening status | trigger`; `trigger`
  forces a play for smoke tests (still honouring reduce-motion).
- Why: the greetd → Hyprland handoff popped straight onto the desktop; a
  short, input-transparent reveal continues the boot splash's (D-044)
  visual language without ever delaying the session.

### D-054 — The daily record may lend the day an accent

- Date: 2026-11-17 · Status: active (narrowed to the terminal greeting by D-079) · Extends D-042, D-047, D-051
- `widgets.dailyAccent.settings = { record; catalog; }` opts a theme in:
  `record` is a prefs path `extras.<ns>.<key>` holding a daily record
  `{ date, id?, index? }` (D-042), `catalog` a theme list it resolves
  against (by `id`, then position). On a day whose record resolves to an
  entry with an `accent` (`#rrggbb`), that colour stands in for
  `accent.primary` everywhere it is read at runtime; otherwise the theme's
  own accent stands. An entry may also name a `sigil` (an `.svg` under
  `assets/`). `mkThemeManifest` validates the record shape, the catalog,
  each accent, entry ids, and that each sigil exists.
- Shell: `modules/dailyAccent/DailyAccentController` resolves the entry
  from `PrefsState` and the manifest, re-reading the date every minute,
  and pushes the colour onto `ShellState.dailyAccent`; `Theme` returns it
  for `colors.accent.primary`. It is derived, never stored: no record
  for today, a midnight rollover, or a theme without the settings gives
  the theme's accent back. Effects and token refs (`"accent.primary"`)
  follow because they resolve through `Theme`.
- Compositor: the Hyprland adapter (D-047) substitutes the day's accent
  before its mapping, so the active border, group borders and every
  `tokens.chrome` gradient ref to `accent.primary` follow. It resolves
  the record from `prefs.json` itself (`rice-switch`, Hyprland reloads);
  the controller re-runs it with `RICE_DAILY_ACCENT=#rrggbb|none` when the
  accent changes within a theme, since prefs.json may lag the claim.
- Terminal: `rice-query daily [path]` prints today's entry; `rice-terminal`
  paints the greeting in the day's accent. `_fastfetch-lib.nix` builds one
  card variant per accented entry (`<theme>@<id>`: frame in its accent,
  its sigil in the same colour); the fish greeting picks today's. The
  greeting's daily line is now resolved before the card is drawn, so a
  draw it claims colours the same greeting, and printed after it as
  before (`RICE_TERMINAL_COLOR=1` keeps captured output painted).
- The shell (`DailyAccentController`) and the CLI tools
  (`nix/_daily-lib.nix`, shared jq) are the only two resolvers.
- Contrast: an accent replaces `accent.primary` as text, so the
  `rice-tools` check holds LOTM's card accents to ≥ 4.5:1 on `bg.base`.
  A theme's pathway hue may be darker; it carries a separate text-safe
  `accent`.
- Rebuild-time surfaces (Plymouth, GTK/Qt, btop/bat/yazi/cava, the
  generated Hyprland config, Starship and Neovim) stay on the theme
  palette; they cannot follow a daily value. The lock screen also keeps
  the theme accent.
- LOTM: one pathway table in `_theme.nix` feeds workspaces, the compass
  and the tarot cards (the manifest's workspaces and compass are
  unchanged). Each card belongs to the pathway of its Tarot Club holder:
  Fool and World → Fool, Magician → Door, High Priestess and Hermit →
  Hermit, Wheel of Fortune → Wheel of Fortune, Star → Darkness (Leonard),
  Moon → Moon.
- Why: the tarot draw was the one daily ritual with no visible
  consequence outside its own card; letting it tint the day makes the
  draw matter, and deriving the tint from the record keeps "restore
  exactly" true without a second piece of state.

### D-055 — HyprFM follows the active rice live

- Date: 2026-11-17 · Status: active · Extends D-039, D-054 · Issue #91
- `rice-hyprfm-theme` (`nix/_hyprfm-theme-adapter.nix`) maps the active
  manifest's colour tokens onto HyprFM's theme keys (base, mantle, crust
  ← `bg.sunken`, surface/overlay ← `bg.surface1/2`, text/subtext/muted ←
  `fg.*`, accent, success/warning/error ← `state.*`), plus a 16-colour
  terminal palette from `palette.legacy` laid out like the console
  palette (D-044) with a surface for black, emitted only when complete.
  It writes `~/.config/hyprfm/themes/rice.toml` atomically; HyprFM
  watches that file and reloads live.
- Folder icons: the same run writes a `rice` icon theme to
  `~/.local/share/icons/rice` (where HyprFM's `auto_refresh_icons`
  watcher looks): Adwaita's folder-shaped `places` icons recoloured by
  role (pale front → the accent, rim and back → darker shades, glints →
  lighter), inheriting Adwaita for everything else. So the folders wear
  the theme's accent, and the tarot card's on a day it lends one.
- Unlike the rebuild-time tool themes (D-051) it is theme-blind and
  applies to every theme: HyprFM has no host colours to preserve, and a
  GUI window beside the bar should switch with it. It follows the day's
  accent (D-054) exactly as the Hyprland adapter does, prefs or
  `RICE_DAILY_ACCENT`.
- Runs: on activation, after a committed `rice-switch` (outside the
  transaction — a failure warns and never rolls a switch back), and from
  `DailyAccentController` when the accent changes within a theme. It does
  nothing where `~/.config/hyprfm` does not exist.
- HyprFM rewrites `config.toml` from its own Settings panel, so Home
  Manager never owns it; activation only sets `[general] theme` and
  `icon_theme` to `"rice"` (the edit upstream documents for scripts),
  leaving every other key the user's. Radius and motion stay HyprFM's settings.
- Why: PCManFM ignored the rice entirely; HyprFM's TOML themes map almost
  one-to-one onto the token roles, and its live reload lets a file
  manager follow switches and the daily draw like the shell does.

### D-056 — Notification personas dress chosen apps' toasts

- Date: 2026-11-18 · Status: active · Extends D-024 · Issue #86
- `widgets.correspondence.settings.personas` is a list of
  `{ apps, label, icon?, sound?, variant? }`. The toast surface matches
  an incoming notification's app name or desktop entry, case-insensitively,
  against `apps`; the first persona that matches dresses its card.
- Variants are the runtime's closed set, currently only `letter`: an
  elevated card with an accent hairline, the persona's icon on a seal
  in place of the urgency stripe. It arrives as a sealed envelope that
  slides in from the screen edge, lifts its flap, then gives way to the
  message. The steps use `Motion.panelOpen`, `cardFlip` and `sealPress`,
  so under reduce-motion the letter is open on arrival.
- The label sits beside the real app name ("discord · borne by …"); the
  summary, body, actions, dismissal and Correspondence history are
  untouched. Urgency still wins: a critical toast keeps the danger
  colours and the critical sound.
- Sound: the persona's `sound` names an `assets.sounds` event and plays
  in place of `notification` under the D-024 rules (after the toast is
  appended, never under DND, muted by default). An unplayable cue falls
  back to `notification`.
- Validated at build: closed keys, non-empty `apps`, string `label`,
  `variant` in the closed set, `sound` present in the theme's sounds,
  `icon` a string (`Theme.icon` resolves it, with runtime defaults).
- LoTM maps Discord, Vesktop, Slack, Signal, Telegram, Element and
  WhatsApp to Reinette Tinekerr's delivery, with a sealed-envelope
  sigil and a short knock-and-flutter cue. Cyberpunk declares none, so
  its toasts are unchanged.
- Why: messages from people are the notifications most worth telling
  apart, and the persona can mark them without hiding which app sent
  them or adding a theme-specific runtime path.

### D-057 — A vocabulary of shell sound cues

- Date: 2026-11-18 · Status: active · Extends D-024 · Issue #82
- The runtime names seven more semantic cues, each played on a
  user-driven edge and silent unless the theme maps it in
  `assets.sounds`:
  - `launcher-open` and `power-open`: the launcher opening, the power
    popout opening (`SoundController`).
  - `workspace`: the focused workspace changing (`SoundController`). It
    is rate-limited to once per 400 ms, waits out the 1.5 s startup
    settle like moods (D-045), and yields to a mood that has its own
    entry sound.
  - `lock` and `unlock`: from `AmbientController.setLocked`. A lock
    plays only when the user asked for it (the veil path, or a direct
    lock with no idle warning up), never one the idle timer took.
    Unlock plays when a lock that was up ends.
  - `satchel-seal`: sealing an artifact in the Satchel (not unsealing).
  - `tarot-flip`: drawing the day's card. Plugins now receive a
    `sound` facade from the mount beside `theme` and `motion`.
- `Sound.play(cue, minInterval)` drops repeats of a cue inside
  `minInterval` ms. Playback stays one command at a time, so cues
  never stack.
- Per-cue opt-out: `prefs.json` `sound.off` lists silenced cues,
  bridged onto `ShellState.soundOff`; set with
  `quickshell -c rice ipc call sound setCue <cue> on|off`. Global mute
  still defaults on (D-024).
- Authoring: LoTM's cues are rendered offline with sox from recipes in
  `assets/sounds/src/` (`render-all.sh`), and the WAVs are committed.
  `lib.sh` levels each cue's RMS to that of `sealed-letter.wav`, with
  per-cue offsets: the workspace whisper sits 12 dB under the rest.
- Cyberpunk maps none of them and stays silent.
- Why: the desktop's ritual moments deserve a voice, but each must
  come from the user's own action, stay quiet by default, and be
  individually removable.

### D-058 — An opt-in ambient sound bed under the governor

- Date: 2026-11-18 · Status: active · Extends D-021, D-024, D-045, D-046 · Issue #83
- A theme may list looped layers in `widgets.soundscape.settings.layers`,
  each `{ sound, volume?, when?, mood? }`: `sound` names an
  `assets.sounds` entry, `volume` is 0–1 within the bed, `when` waits
  for a sky condition (`rain`, `fog`, `fullMoon`), and `mood` ties the
  layer to a workspace mood. While a screen shows that mood's
  workspace, its layers replace the rest, as mood effects replace the
  theme's layers. The manifest validates all of it.
- The bed is the one sound that does not come from a user's action, so
  it is opt-in twice: sound must be unmuted (D-024) and
  `prefs.json` `sound.soundscape` true, set with
  `quickshell -c rice ipc call ambient setSoundscape on|off`.
- The governor (`AmbientController.soundscapeAllowed`) owns when it may
  run: opted in, unmuted, ambient mode not off, no reduce-motion, not
  on battery, no fullscreen window, not locked, and no MPRIS player
  playing. The visual-only gates (theme ambient tier, layers present)
  do not apply. `ambient status` reports it under `soundscape`.
- One managed process, `rice-soundscape-play <volume> <file>...`,
  loops every layer on its own period through sox and plays the mix
  as one PipeWire stream (`node.name` `rice-soundscape`). It fades in
  over 3 s; on SIGTERM it fades the stream's volume out before it
  stops; it stops by itself if its parent shell goes away. Off means
  no process. Layer changes settle for 800 ms before the player
  restarts, so a passing workspace or a flicker of media doesn't
  stutter it; a player that ends on its own stays down until the next
  change.
- Weather (D-046) is fetched when an effect preset or a bed layer keys
  on `rain` or `fog`.
- Authoring: LoTM's beds are sox recipes in `assets/sounds/src/`
  (`bed-*.sh`), rendered to small mono Ogg files that are committed.
  `lib.sh` gains `impulses` (seeded random clicks for drops and
  crackle) and `loop` (crossfades the tail over the head so the loop
  has no seam).
- Cyberpunk declares no bed and stays silent.
- Why: atmosphere you hear is as much a part of the world as the fog
  you see, but a sound that plays by itself must be asked for, must
  give way to the user's own media, and must leave nothing running
  when it is off.

### D-059 — VS Code, Spotify and Discord themes from tokens

- Date: 2026-11-18 · Status: active · Extends D-051 · Issue #85
- `integration.tools` also accepts `vscode`, `spotify` and `discord`.
  `_tools-lib.nix` generates each from the configured theme's colour
  tokens and `palette.legacy`, with no hand-copied hex values:
  - VS Code: a colour theme extension (`rice.rice-theme`) built by Nix,
    labelled with the theme's display name, dark or light by
    `bg.base`'s luminance. The workbench wears the bar's surfaces
    (sunken chrome, mantle side bar and panels, base editor) and the
    accent marks focus, the active tab and buttons. Code colours come
    from the syntax role table bat already used, now shared, so code
    reads the same in both. `programs/vscode.nix` sets its scheme-map
    theme with `mkDefault`, so the rice's choice wins and a theme that
    does not opt in keeps the map exactly.
  - Spotify: a Spicetify `customColorScheme` on the default theme.
  - Discord: a Vencord CSS theme that only overrides Discord's own
    colour variables on the dark appearances, without class selectors,
    so a client update can at worst leave a surface stock. It is
    enabled through Vencord's `enabledThemes`.
- Client changes (each chosen by the user for #85), made in the program
  modules for every theme on Hyprland hosts, so switching themes never
  switches clients or logins:
  - Spotify is patched by Spicetify (`spicetify-nix` flake input). With
    no scheme the default theme keeps Spotify's own look.
  - Discord is replaced by Vesktop (Vencord built in), configured with
    home-manager's `programs.vesktop`; Vesktop's and Vencord's settings
    stay writable and ours are merged in at activation.
    `enabledThemes` defaults to empty. The window route to workspace 4
    matches `discord|vesktop`.
  - GNOME hosts keep the official clients.
- Spicetify's options are one submodule, so the rice conditions the
  scheme's value, not the block, on `programs.spicetify.enable`;
  guarding the block on its own option recurses.
- Cyberpunk opts into none of them: stock Spotify and Discord colours,
  and VS Code's scheme map as before.
- Why: the apps open beside the shell all day; they should wear the
  same palette, generated so a token change reaches all of them.

### D-060 — Zen's chrome and a new-tab page from the rice

- Date: 2026-11-18 · Status: active · Extends D-042, D-051, D-059 · Issue #84
- `programs/zen.nix` builds Zen through nixpkgs' `wrapFirefox` itself,
  as the flake does, and adds `program.zen.autoconfig`: JavaScript
  appended to Zen's `mozilla.cfg`. While it is non-empty, the autoconfig
  sandbox is off, because the code needs chrome privileges; the file is
  in the store, so the sandbox guarded nothing. `program.zen.newtabLinks`
  holds the page's links (user data, not theme data).
- Chrome (`integration.tools` lists `zen`): `_browser-lib.nix` generates
  a stylesheet that sets only Zen's and Firefox's colour variables,
  inside `@-moz-document url("chrome://browser/content/browser.xhtml")`.
  Autoconfig registers it as a user sheet through the style-sheet
  service, so no profile directory (whose name is random) is touched and
  `userChrome.css` stays the user's. A user `!important` beats the
  workspace gradient, text colour and primary colour that Zen writes
  inline on its own elements, so those, the colour scheme and the
  floating URL bar's background are set on every chrome element. The
  workspace name takes the display font.
- New-tab page (`widgets.newtab.settings = { title; tagline?;
  epigraphs?; daily?; labels?; }`): a static page built per configured
  theme into `~/.local/share/rice/newtab/index.html`. Autoconfig makes it
  the new-tab URL (`AboutNewTab.newTabURL`) and the default homepage, and
  turns off `zen.urlbar.replace-newtab` by default so Ctrl+T opens a tab.
  All three are defaults, so `about:config` still wins. The page works out
  the real date and picks the epigraph by day of the month, as the
  dashboard does. It renders all text with `textContent`.
- Live part: `modules/newtab/NewtabFeed` writes
  `$XDG_STATE_HOME/rice/newtab-feed.js` (`window.riceNewtab = { updated,
  theme, weather, moon, sky, omen }`), which the page loads as a script;
  file pages can load scripts but not fetch JSON. Weather is null until
  `WeatherState` has a reading; `omen` is today's record formatted like
  the terminal greeting (D-042) or the pending label. It is rewritten
  when an input changes and every half hour, and only for themes with the
  settings. Without the file the page says the shell sent nothing, beside
  "weather unavailable".
- Chrome and page follow the configured theme at rebuild like the other
  tools (D-051); the feed follows the running shell.
- Cyberpunk declares neither, and Zen stays stock.
- Why: the browser is the window open most of the day; it should belong
  to the world without hiding the real date, weather or URL bar, and
  without selectors that break on each Zen release.

### D-061 — The launcher remembers launches and leads with one result

- Date: 2026-11-19 · Status: active · Extends D-023, D-025
- Launches are recorded as frecency in PrefsState extras
  (`launcher.history`: `{ <desktop id>: { count, last } }`, at most 64
  ids). `utils/Frecency.qml` holds the pure math: launch count weighted
  by age bucket (4 h, 1 day, 1 week, 1 month, older), so a few recent
  launches outrank many stale ones.
- `AppsState.search(query, limit, boosts)` takes the scores from the
  caller (services never import services). An empty query lists used
  apps first, then the rest alphabetically. With a query, the usage bonus
  (at most 1200) reorders matches within about one match tier, so an
  exact or prefix match still beats a loose one, and a non-match is
  never lifted. Scores are taken when the launcher opens, so results
  hold still while it is up.
- Layout: the top result is a focus card (large icon, name in the
  display face, generic name, comment); the rest follow as a scrolling
  list. Up/Down and Tab/Shift+Tab move the selection; Left/Right stay
  with the text cursor. `widgets.launcher.settings.columns` is gone;
  `visibleRows` (default 7) sets the list height.
- Why: the grid gave every match the same weight, and a launcher
  that forgets what you open is slower each time it is used.

### D-062 — The shell is the session's polkit agent

- Date: 2026-11-19 · Status: active · Extends D-008, D-023
- `services/polkit/PolkitState` wraps Quickshell's `PolkitAgent`; the
  response goes straight from `submit()` to the agent and is never
  stored or logged. `modules/polkit/PolkitPrompt` shows the real
  message, identity, action id and PAM prompt under theme copy from
  `widgets.polkit.settings` (closed keys, validated), on the focused
  screen, with exclusive keyboard focus. A failed attempt clears the
  field, shakes the card and shows `retryText`.
- On rice hosts `polkit-gnome` no longer autostarts (one agent per
  session) but stays defined for recovery.
- Why: privileged prompts were the last plain GTK dialog in the session.

### D-063 — The bar can be a flush rail with end caps

- Date: 2026-11-20 · Status: active · Extends D-006, D-023, L-011 ·
  Brief: `docs/design/bar-brass-rail.md` (#92, phase 1)
- `widgets.bar.settings` (closed keys, validated) picks the bar's frame:
  `style = "floating"` (default, the rounded rect) or `"rail"`, flush to
  the top edge. The rail draws `frame.body` nine-sliced across the
  window (its middle repeats, so ticks run like a ruler) and
  `frame.plaque` behind each region, each `{ src; slice = [l t r b]; }`
  under assets/. Without pieces it draws the same shape from tokens.
- `caps.start` / `caps.end` (`{ action; plate?; emblem?; turn?; }`) are
  end caps bound to `launcher`, `dashboard` or `power`. The plate turns
  `turn` degrees (default 30, `Motion.instrumentSettle`) while that
  surface is open and back when it closes; it never spins. `glow` names
  token refs for the hub light at rest and on hover. A `power` cap takes
  the place of the power glance, whose popout it opens.
- The floating inset is drawn inside the bar window, with an input mask,
  instead of as layer-shell margins: margins committed before the
  manifest arrived were never re-applied.
- `widgets.clock.settings.layout = "inline"` puts the date beside the
  time for shallow bars; `"stacked"` stays the default.
- LoTM: the Brass Rail at 44 px; a brass cog with the Fool in its hub
  opens the launcher, a scalloped seal holds power. Cyberpunk is
  unchanged.
- Why: the floating pill read as a generic rice; the rail makes the bar
  an instrument without any per-theme code in the runtime.

### D-064 — Instruments on the rail, and an opt-in tray hatch

- Date: 2026-11-20 · Status: active · Extends D-016, D-063 ·
  Amends L-009, D-036 (tray placement only) · Brief:
  `docs/design/bar-brass-rail.md` (#92, phase 2)
- Icons stay semantic names in `assets.icons`; `Theme.hasIcon(name)` lets
  a glance prefer a finer variant the theme names. The system glance uses
  `wifi-0`…`wifi-3` for signal strength (else `wifi`). A theme with
  `battery-ink` gets a vial gauge: `components/GaugeIcon` draws the ink
  below the charge line under the `battery` glass, and `battery-ink-low`
  replaces it at `lowBattery`.
- `widgets.system.settings`: `bluetooth` (show the icon while the adapter
  is on), `batteryGauge = { full; empty; }`, `lowBattery` (default 0.2),
  `criticalBattery` (default 0; below it the battery pulses on
  `Motion.alarm`, the only flashing in the bar besides urgent
  workspaces), `showTray`.
- `widgets.media.settings`: `hideIdle` collapses the glance with no track;
  `disc` keeps the `music` icon and turns it on `Motion.revolution` while
  playing, only while the ambient governor runs.
  `widgets.monitor-profile.settings.showLabel = false` leaves the icon
  alone; the profile name stays in the popout. A glance whose width is 0
  takes no slot in the bar row.
- The `tray` widget (off by default) is the hatch: the first `maxInline`
  (1–6) icons on the bar, a count of the rest, `tone = "sepia"` muting
  app colours until hover, gone when the tray is empty; its popout holds
  every item with app-native menus (`components/TrayGrid`, shared with
  the system popout). L-009 and D-036 kept tray icons out of the bar to
  avoid unbounded chrome; the hatch is bounded and opt-in, and a theme
  that enables it sets `system.settings.showTray = false` so the tray
  lives in one place.
- All new keys are closed and validated, with must-fail cases.
- LoTM: hand-drawn instruments in `assets/instruments/` (antenna, conduit,
  speaking horn and its stopper, vial glass, ink and bubbles, tuning fork,
  lens, phonograph disc), drawn in-repo so there is no licence question.
  Cyberpunk is unchanged.
- Not done: the title marquee and the lens tooltip; the title elides and
  the profile name is in the popout.
- Why: the bar's right side read like a phone status bar; the instruments
  carry the same readings in the world's own objects.

### D-065 — Workspace sigils in bezels, with a needle

- Date: 2026-11-20 · Status: active · Extends D-063 · Brief:
  `docs/design/bar-brass-rail.md` (#92, phase 3)
- `HyprState` now tracks `workspaceWindows` (`{ id: window count }`) and
  `urgentWorkspaces` from Quickshell's Hyprland workspaces, and gains
  `moveFocusedWindow(id)`, which uses the same dispatcher as Super+Shift+N.
- `widgets.workspaces.settings.bezel = { plate?; activePlate?; needle?;
  urgent?; }` (closed, validated) turns on bezel mode. In bezel mode each
  icon shows a state:
  - **Empty:** monochrome at 45%.
  - **Occupied:** full colour at 80%, with a rivet below the bezel.
  - **Active:** the polished plate, full colour and a glow in the
    workspace colour.
  - **Urgent:** the rim pulses twice in the `urgent` colour token on
    `Motion.alarm`, then holds until the workspace is visited.
  A needle under the strip sweeps to the active bezel on
  `Motion.instrumentSettle`. Without `bezel` the strip is unchanged.
- In every theme, a middle click on a workspace moves the focused window
  there.
- LoTM: aged and polished brass bezels, a brass needle, a ritual-crimson
  urgent rim, and sigils at 20 px.
- Not done: scrolling over the strip turns the carousel, which is phase 4.
- Why: the sigils were the bar's one in-world element, but they did not
  show which workspaces held windows or needed attention.

### D-066 — Window captures come from the compositor's held frame

- Date: 2026-11-20 · Status: active · Extends D-065 · Brief:
  `docs/design/bar-brass-rail.md` (#92, phase 4a spike)
- Spike, run on shitbox (Hyprland 0.56.0, Quickshell 0.3.2). Hyprland
  offers `hyprland_toplevel_export_v1` and
  `ext_foreign_toplevel_image_capture_source_v1`.
- `ScreencopyView { live: false; captureSource: HyprlandToplevel.wayland }`
  gets a real frame for every window, including windows on inactive
  workspaces. Five windows arrived about 41 ms after the shell started.
- A hidden window's frame is the last one it drew while visible. Hidden
  clients get no frame callbacks, so they stop drawing. A clock terminal
  moved to workspace 9 and captured twice, 3 s apart, read the same time
  both times: the moment it left view. `captureFrame()` gives the same
  frame again.
- Consequence for phase 4c: the compositor already is the cache. The shell
  keeps no capture cache of its own. The card's fallback chain becomes
  capture, then app icons, then sigil only.
- Rules for the carousel:
  - Capture once per open and never stream (`live: false`).
  - Call `Hyprland.refreshToplevels()` on open. Until then a toplevel's
    `workspace` and `lastIpcObject` are empty.
  - `lastIpcObject.at` is in global layout coordinates. Subtract the
    monitor's position before placing a window in the miniature.
  - `sourceSize` is the full window size, whatever `constraintSize` says.
    Each capture holds a full-resolution buffer (about 8 MB for a
    1902×1110 window), so release the views when the carousel closes.
- Why: the brief planned a shell-side cache in case inactive windows could
  not be captured. They can, and the held frame is already the freshest
  one that exists.

### D-067 — The workspace carousel: a drum of card plates

- Date: 2026-11-20 · Status: partly superseded by D-069 (triggers,
  placement and size) · Extends D-065, D-066 · Brief:
  `docs/design/bar-brass-rail.md` (#92, phase 4b)
- New module `modules/workspaceCarousel`:
  - `CarouselController` decides when the carousel opens, turns and
    closes. ShellState carries its fields (`carouselScreen`,
    `carouselWorkspace`, `carouselReason`, `carouselSerial`,
    `carouselAnchor`, `carouselPointer`, `carouselDrumHovered`).
  - `WorkspaceCarousel` is one surface per screen.
  - `CarouselCard` draws each card.
- It is on only when a theme sets `widgets.workspaces.settings.carousel =
  { card?; nameplate?; copy?; }` (closed, validated). Card and nameplate
  are `{ src; slice; }` pieces under `assets/`; `copy` is `{ none; one;
  many }` with `{n}` for the count. Without it nothing changes, so
  Cyberpunk's strip is pixel-identical.
- Triggers. Every opening has a reason:
  - **switch:** a workspace switch on a screen shows the carousel turned
    to the new card. It closes 900 ms later unless the pointer is on the
    strip or the drum. Only workspaces with a card show it.
  - **hover:** resting on the strip for 350 ms opens it, and it follows
    the bezel under the pointer. It closes 300 ms after the pointer is
    on neither the strip nor the drum.
  - **scroll:** scrolling over the strip or the drum turns it without
    switching. It closes like hover.
  - **keys:** a deliberate open over IPC (`carousel open` / `toggle`,
    ready for a keybind). It stays until Esc, Enter or a click, and is
    the only reason that takes the keyboard. Opened by the pointer, the
    carousel gets focus only when clicked; a switch never takes it.
  - **Choosing:** clicking a card switches to it and closes the
    carousel; the switch that follows does not reopen it. ←/→ turn it,
    Enter switches to the front card.
- Drum layout:
  - The front card is 320×200 and sits under the workspace strip, kept
    on screen.
  - Two neighbours on each side sit 35° apart on a drum of radius 340.
    Each step away is smaller (−16% scale) and dimmer. Further cards are
    hidden.
  - The drum turns on `Motion.instrumentSettle`. With motion reduced or
    the ambient governor off, the cards take their new places at once
    and cross-fade.
- Card face:
  - The sigil, large, with a glow in the workspace colour.
  - Behind it, the app icons of its windows (up to 6, then +N),
    desaturated. With no windows, an ink fog in its colour.
  - Along the bottom, a nameplate with the label in the display face in
    small caps, and the window count.
  - Captures replace the icons in phase 4c (D-066).
- Service additions:
  - `HyprState.workspaceSwitched(screenName, id)`, which skips each
    screen's first report.
  - `HyprState.workspaceApps(id)`.
  - `AppsState.iconFor(appId)`.
- LoTM: a tarot plate in umber inside a double brass rule, an iron
  nameplate between two rivets, and the copy "Unclaimed", "1 window",
  "{n} windows".
- Why: the brief's signature moment. Workspaces had names and sigils
  but nothing showed what was on them before you went there.

### D-068 — Carousel cards show their workspace, captured

- Date: 2026-11-20 · Status: active · Extends D-066, D-067 · Brief:
  `docs/design/bar-brass-rail.md` (#92, phase 4c)
- With `widgets.workspaces.settings.carousel.capture = { tint?; strength?;
  }` (closed, validated), each visible card shows its workspace in
  miniature behind the sigil:
  - Each window is a `ScreencopyView` with `live: false`: one frame, never
    a stream.
  - Windows are placed by Hyprland's geometry on the workspace's monitor,
    the most recently focused on top.
  - The miniature is washed with the `tint` token at `strength` (default
    `accent.primary` at 0.4), desaturated by half and slightly dimmed.
  - The sigil moves to the middle of the miniature.
- Fallback chain, as D-066 set it: the capture, then app icons until a
  frame arrives (or with no `capture`), then the sigil alone. A workspace
  with no windows still shows its ink fog.
- `HyprState`:
  - `refreshWindows()` re-reads monitor and window geometry. The
    carousel calls it when it opens and whenever window counts change.
  - `workspaceLayout(id)` gives the windows in the monitor's logical
    pixels, with the monitor offset taken off and scale and rotation
    accounted for.
- Memory: only cards in view hold captures (each a full-size buffer), and
  closing the carousel unloads its surface and releases them all.
- LoTM: `capture = { tint = "accent.primary"; strength = 0.4; }`, a
  sepia wash in the brass gold.
- Verified on the live Hyprland session with a harness that ran only the
  carousel from a scratch copy, so the user's shell was untouched. Zen,
  Slack with Vesktop, and two terminals on inactive workspaces all
  showed real content.
- Gotcha: a negative `z` puts an item below its siblings, so a window
  stack with negative z needs its own container above the backdrop.
- Why: the brief's card face. The sigil says which workspace it is; the
  capture shows what is on it.

### D-069 — The carousel takes the whole screen, opened on purpose

- Date: 2026-11-20 · Status: active · Supersedes part of D-067 (triggers,
  placement and size) · Extends D-068 · Brief:
  `docs/design/bar-brass-rail.md` (#92)
- The user's call after seeing D-067 live: the 320×200 drop-down was too
  small to read a capture.
- Now a full-screen overlay on the focused screen, over a dimmed backdrop:
  - The front card is about half the screen wide and shaped like the
    screen.
  - The drum's radius and the card chrome scale with it
    (`CarouselCard.unit`, `aspect`).
- Opening: only on purpose, with Super+Tab (`carousel toggle`), facing the
  focused screen's workspace.
  - D-067's switch, hover and scroll triggers are gone. A workspace switch
    just switches, and the bezel needle is its feedback. The strip and
    glance are back to D-065.
  - A switch made while it is open turns it to the new card.
- Inside it:
  - ←/→, Tab or the wheel turn it, and a digit faces that workspace.
  - Enter or a click on a card goes there.
  - Esc, Super+Tab again, or a click outside closes it.
  - It holds the keyboard while open.
- `ShellState` keeps only `carouselScreen` and `carouselWorkspace`, and
  opening it closes the other centre-stage surfaces.
- `HyprState.refreshWindows()` waits until 1.5 s after the service
  starts. In Quickshell 0.3.2, `refreshToplevels()` called before the
  first workspace load leaves only a placeholder workspace (−1). This was
  reproduced every time in a harness and fixed by the wait.
- Verified on the live Hyprland session with a carousel-only harness
  (the counts were right and captures readable at full size), plus
  `rice-lint`, manifest validation and the shitbox build.
- Why: the captures are the point of the carousel, and they need room.

### D-070 — Hinged-plate popouts, and reduce-motion fades instead of jumps

- Date: 2026-11-20 · Status: active · Narrows D-022 · Extends D-063 ·
  Brief: `docs/design/bar-brass-rail.md` (#92, phase 5, the last)
- Under the rail bar style, every bar popout is a hinged plate. That
  covers system, media, power, monitor and the tray hatch.
  - **Placement:** it hangs flush from the rail. The popout window already
    starts below the bar's exclusive zone, so the plate sits at its top.
  - **Frame:** `widgets.bar.settings.frame.popout = { src; slice; }`
    (validated), or a token plate with small corners without one.
  - **Opening:** it swings down about its top edge from edge-on (−90°) on
    `Motion.hingeSwing` (base duration, enter curve), overshoots by 2°,
    and settles flat on `Motion.hingeSettle`.
  - **Closing:** it swings back up on `panelClose`.
  - **Content:** unchanged. The floating style (Cyberpunk) is unchanged.
- Reduce-motion: D-022 made every animation instant. For the rail's
  moments that turn or sweep, the brief asked for a fade instead of a
  jump.
  - **New spec `Motion.fade`:** the fast duration and standard curve. It
    keeps its duration under reduce-motion and is 0 only when the theme
    turns motion off.
  - **`Motion.calm(spec)`:** gives `spec` while motion is on and `fade`
    otherwise, for the opacity half of a moment.
  - **`components/FadeIn`:** fades its target back in on `fade` when a
    reading changes under reduce-motion.
  - **Covered:** the cog notch and the needle fade in at their new
    position. The carousel opens and closes with a fade, and turns with a
    fade under reduce-motion or the governor. A hinged plate fades in
    rather than swinging.
  - Everything else keeps D-022's instant behaviour, including small
    state changes and the urgent and critical pulses, which do not run
    under reduce-motion.
- LoTM: a dark umber plate in a brass rule, hung from a brass hinge leaf
  with a barrel in each top corner and a rivet in each bottom corner.
- Verified headless:
  - The swing (mid-swing and settled frames).
  - The plate sitting flush under the rail.
  - The reduce-motion fades of the plate and the cog, observed with the
    fade stretched in a scratch copy.
  - Cyberpunk's popout matches the committed runtime apart from live
    Bluetooth order.
  - `rice-lint`, manifest validation and the shitbox build pass.
- Why: the brief's last phase. The popouts were the last rounded,
  floating cards on a brass rail, and reduce-motion users lost every
  ceremonial moment to a jump.

### D-071 — Breathing room on the rail: inset and plaque padding

- Date: 2026-11-20 · Status: active · Extends D-063 · Brief:
  `docs/design/bar-brass-rail.md` (#92, after live use)
- The user's call after seeing the rail live: the caps touched the screen
  edges, and the bezels and icons pressed against the plaques' bevels.
- New `widgets.bar.settings` keys, rail only, closed and validated:
  - `inset` (int, 0–16): keeps the caps and plaques that far off the
    rail's top and sides, so the rail's border shows. The bottom keeps
    the same inset plus `space.xs` above the rule. The caps size to fit
    (`RailCap.plateSize` is now settable).
  - `plaquePad` (int, 0–24, default `space.sm`): the room between a
    plaque's bevel and its region. Plaques fill the height inside the
    inset, so the vertical room is whatever the content leaves.
- LoTM:
  - `metrics.bar.height` goes from 44 to 56, with `inset = 5` and
    `plaquePad = 12`.
  - The rail body's slice becomes `[24 1 24 10]`, so the ticks and rule
    along the bottom keep their size at any height.
- The floating style is unchanged; Cyberpunk's bar renders the same as
  before.
- Why: the brass frame is the look, and it only reads when the border and
  bevels have space around them.

### D-072 — Square gilt windows: the theme shapes the window frame

- Date: 2026-11-20 · Status: active · Extends D-049 · Supersedes the part of
  D-047 that kept rounding out of the theme mapping
- The user's call: rounded corners do not fit the Victorian rice. They
  chose native square gilt frames over plugins. Ornaments come next
  (shell-drawn, to be prototyped), and brass-framed shell surfaces after
  that.
- `tokens.chrome` grows, all optional and validated by `mkThemeManifest`
  and by the adapter:
  - `border.inactive`: a gradient of 1–4 colour token refs.
  - `border.width`: 1..8.
  - `rounding`: 0..32.
  - `shadow = { color?; range?; power?; offset?; }`, where `color` is a
    token ref, `range` is 0..64, `power` is 1..4, and `offset` is
    `[x y]` with each value in −32..32.
- The adapter emits these after a baseline chunk that restores the
  generated config's shape, so switching to a theme without them gives
  back its rounding, border width and shadow:
  - `general.border_size` and `decoration.rounding` come from the base
    style.
  - `decoration.shadow` holds Hyprland's defaults, now explicit in
    `programs/hyprland/_chrome.nix` and set by the generated config.
  - The shadow colour is the token at alpha `dd`.
- Gaps stay with the generated config.
- LoTM:
  - Rounding 0 and a 3 px border.
  - The active gilt gradient as before.
  - Inactive windows in dark iron (`bg.surface2` to `bg.sunken`).
  - An umber shadow (`bg.sunken`, range 18, power 2, offset 3 5).
- Tests:
  - The switch test asserts LoTM's chunk, and the baseline coming back
    on Cyberpunk.
  - Seven must-fail cases were added.
  - An old case that used `chrome.shadow` as an unknown key now uses
    `chrome.glow`.
- Verified live: the generated chunk was applied to the running Hyprland
  (`hyprctl eval` accepted it; options read back as rounding 0, border
  3, shadow 18 at 3 5), and a screenshot showed square frames.
- Why: brass and iron are cut square; the rounded corners were the last
  piece of the generic look on the windows themselves.

### D-073 — Solid gilt on focus: no border sweep or colour fade

- Date: 2026-11-20 · Status: active · Amends D-049 and D-072 for LoTM
- The user's call: the focused window gets one solid colour, with no
  colour animation on the border.
- `tokens.motion.compositor.borderFade = "off"` (the only value) turns
  off Hyprland's `border` animation, so focus changes snap. The adapter
  now restores the `border` leaf from the baseline on every apply, so a
  theme without it (Cyberpunk) keeps the generated fade.
- LoTM: `chrome.border.active = [ "accent.primary" ]`, a single stop, so
  the frame is solid gilt; `borderSweep` is dropped; `borderFade = "off"`.
  The unfocused dark-iron gradient and the group-bar cards stay.
- Tests: the switch test asserts the leaf is disabled for LoTM and
  restored for Cyberpunk; two must-fail cases (`"slow"`, `false`).
- Why: a moving glint and a cross-fade read as modern UI; brass doesn't
  shimmer when you look at it.

### D-074 — Window ornaments: shell-drawn corner pieces on window frames

- Date: 2026-11-20 · Status: active · Extends D-072
- The second step toward Victorian window chrome, after square frames.
  Hyprland cannot decorate a frame without a plugin, so the shell draws
  the ornaments; the user went ahead with them after the prototype.
- `widgets.ornaments.settings = { corner; size?; reach?; inactive?; }`
  opts a theme in, validated with closed keys and six must-fail cases.
  `corner` is the top-left piece; the shell mirrors it for the others.
- `modules/windowOrnaments`:
  - `OrnamentController` (in `shell.qml`) re-reads window geometry, which
    Hyprland only reports on request. After any event that moves windows
    (open, close, move, float, fullscreen, workspace or group changes) it
    raises `ShellState.windowsSettling`, waits 450 ms for the window
    motion to land (60 ms when motion is reduced), re-reads, and lowers
    it. Focus changes re-read at once. A 1 s re-read catches drag-moves
    and resizes, which raise no event.
  - `WindowOrnaments` (one per screen, Top layer, empty input mask, no
    keyboard focus) draws the four corners of every window on the
    screen's active workspace from `HyprState.windowFrames(screen)`. It
    skips corners covered by a floating window above, draws nothing while
    the workspace has a fullscreen window, and fades out while windows
    settle and back in on `Motion.fade`.
- `Theme.frameWidth` reads `tokens.chrome.border.width` (default 2, the
  generated config's), so the art lines up with the frame.
- LoTM: `assets/chrome/corner.svg`, a gilt diamond boss with a rivet, arms
  along the border and a leaf between two scrolls, 48 px with reach 6,
  at 0.55 on unfocused windows.
- Known limits: ornaments trail a drag by up to a second, and the scrolls
  reach about 10 px over each window's corner.
- Verified: the checks, the shitbox build, and the working-tree runtime on
  the live Hyprland (corners on all three monitors, dimmed when unfocused).
- Why: the user asked for ornament on the frames, "nothing too modern";
  square gilt alone read as plain.

### D-075 — Window ornaments from a Hyprland plugin (spike)

- Date: 2026-11-20 · Status: wired in by D-080 · Extends D-074
- The user asked to make the ornaments follow every frame. Only the
  compositor knows where a window is on each frame, so this is a plugin:
  `pkgs/rice-ornaments` (`rice_ornaments`, about 250 lines of C++, after
  the official borders-plus-plus).
  - Each window gets a decoration on the "over" layer with absolute
    positioning, so it reserves no space. It queues its own render-pass
    element and draws four textures (`tl/tr/bl/br.png`) at the frame's
    corners. The frame comes from the window's animated position plus the
    workspace and floating offsets of that frame, expanded by the border.
  - Fullscreen and undecorated windows (border size 0) get nothing.
    Unfocused windows draw at `inactive`.
  - Options: `plugin:rice_ornaments:{corner,size,reach,inactive}`, where
    `corner` is the directory holding the four PNGs; the others mean what
    they do in D-074.
- Built with `mkHyprlandPlugin` against `inputs.hyprland`, exposed as
  `packages.rice-ornaments`. The `rice-ornaments-plugin` flake check
  builds it, so a Hyprland bump that breaks the plugin API fails the
  check before it reaches a rebuild. The plugin compares its build hash
  with the running Hyprland's and refuses to load on a mismatch.
- Tested in a nested Hyprland (Hyprland running in a window, never the
  live session): it loads from `hl.plugin.load`, draws on three
  terminals, tracks a window swap mid-animation at fractional positions,
  follows focus (bright on focus, dim elsewhere), scales on a HiDPI
  output, and unloads cleanly with the windows intact.
- Hazard found: a config that sets `plugin.rice_ornaments.*` when the
  plugin is not loaded is a Lua config error, and Hyprland drops into
  emergency mode with no keybinds. So plugin options must never be
  written into the generated config unconditionally. The integration has
  to set them at runtime (`hyprctl eval`) and only after confirming the
  plugin is loaded, with the shell overlay (D-074) as the fallback.
- Not yet decided (the user's call after living with it): loading it at
  login, the adapter setting the options from `widgets.ornaments`, PNGs
  rendered at build from the theme's SVG, and the shell overlay standing
  down while the plugin is loaded.
- Why: the shell overlay cannot follow drags and window animations; the
  compositor can.

### D-076 — Brass-framed shell surfaces

- Date: 2026-11-20 · Status: active (panel plate replaced by the window frame, D-081) · Extends D-070, D-072
- The third step toward Victorian chrome, as the user chose ("Brass-framed
  plates"): the big shell surfaces get square, nine-sliced brass plates
  like the rail popouts.
- `widgets.plates.settings = { panel?; toast?; }`, each `{ src; slice; }`
  under assets/, validated with closed keys and four must-fail cases.
- `components/PlateFrame` (role `panel` or `toast`) draws the piece as the
  first child of a surface's frame. While it is shown, the surface turns
  its own radius, fill and border off; without theme data nothing
  changes. Used by the launcher, dashboard and notification centre
  (`panel`) and by toasts (`toast`, not letters, which keep their
  envelope).
- State that lived in the old border moves inside the plate: an urgent
  toast gets a `state.danger` rule, and do-not-disturb gets a
  `state.warn` rule inside the centre's plate.
- LoTM: `bar/panel.svg` [18 18 18 18], a square umber plate in a double
  brass rule with a diamond boss and gilt leaf in each corner, all inside
  the surfaces' 16 px content margin; `bar/toast.svg` [10 10 10 10], a
  small riveted plate inside the toasts' 12 px margin. No layout changed.
- Verified: headless shots of all four surfaces with the plates, and the
  launcher's rounded panel unchanged without them.
- Why: the rounded glass panels were the last generic surfaces; brass
  plates match the rail, the popouts and the window frames.

### D-077 — The boot ring is drawn full

- Date: 2026-11-20 · Status: active · Amends D-044
- The user's call: keep the passphrase screen, but drop the ring
  animation and show the ring full from the start. Phase 1 of the
  Threshold, Gate and Vigil brief (`docs/design/threshold-gate-vigil.md`).
- The splash renders one full ink ring (`ring.png`, the same bleed and
  ink passes as before) instead of 60 frames plus 59 seep segments, and
  the script drops boot progress, the seep and the shutdown drain. The
  ring fades in with the sigil and stays full on boot, shutdown and
  reboot.
- Boot progress is unused for now; the planned ascent (phase 3 of the
  brief) will drive it, so impermanent hosts keep persisting
  `/var/lib/plymouth`.
- The `rice-boot` check now expects `ring.png`.
- Why: a filling ring reads as a loading bar; a closed ring reads as a
  seal, which is what the Threshold is.

### D-078 — The frame stays gold: the daily accent leaves the chrome

- Date: 2026-11-20 · Status: active (runtime helpers removed by D-079) · Amends D-054
- The user's call, after the day's draw (The Moon, `#dd7a6e`) turned the
  window borders red: borders, bezels, corner pieces and the rail keep
  the theme's gold and never follow the daily accent.
- The Hyprland adapter no longer reads the daily accent at all: borders,
  group bars and the shadow resolve against the theme's own palette, and
  `RICE_DAILY_ACCENT` is ignored there. `DailyAccentController` stops
  re-running it when the day changes; HyprFM still takes the day's accent.
- Runtime: `Theme.colors.accent.frame` is the theme's own accent, and
  `Theme.tokenColor(ref)` resolves a colour ref against the theme's
  palette without the day's accent. The rail caps (outline, candle glow,
  hover glyph), the floating bar's rule and the workspace rivet use them.
  The SVG art (bezels, plates, corners) was never tinted.
- Content still follows the day: glances, text accents and anything else
  reading `accent.primary`.
- Tests: the D-054 switch case now asserts the daily colour never appears
  in the Hyprland chunk, from prefs or from `RICE_DAILY_ACCENT`.
- Why: the brass is the machine and should not change; the day's colour
  belongs to what the machine shows.

### D-079 — The day's card colours only the terminal greeting

- Date: 2026-11-20 · Status: active · Supersedes the shell and HyprFM parts
  of D-054, and D-078's `accent.frame` / `tokenColor`
- The user's call: text and chrome in a different colour from the brass
  looked wrong; only the terminal greeting should follow the day's card.
- The shell no longer has a daily accent: `modules/dailyAccent` and
  `ShellState.dailyAccent` are gone, and `Theme.colors.accent.primary` is
  always the theme's own. D-078's frame-only helpers are removed again;
  the rail uses `accent.primary` as before.
- HyprFM (`rice-hyprfm-theme`) and the Hyprland adapter (D-078) ignore
  it; `RICE_DAILY_ACCENT` is no longer read anywhere.
- Kept: `widgets.dailyAccent.settings` and its validation, the shared jq
  resolver (`nix/_daily-lib.nix`), `rice-query daily`, the
  `rice-terminal` greeting in the day's accent, and the fastfetch card
  variant per accented card.
- Tests: the HyprFM check asserts the theme accent with a daily record
  and an override present.
- Why: the brass is one colour; the day's draw is a greeting, not a
  repaint.

### D-080 — The ornaments plugin is wired in; the shell overlay is the fallback

- Date: 2026-11-20 · Status: active · Completes D-075 · Extends D-074
- The user's call: integrate the plugin fully.
- Loading: with rice enabled, `wayland.windowManager.hyprland.plugins`
  lists `packages.rice-ornaments`, so the generated config starts with
  `hl.plugin.load(...)`. The config never sets plugin options.
- Options: `rice-hyprland-theme` asks `hyprctl -j plugin list` after
  applying a theme; only when `rice_ornaments` is loaded does it
  `hyprctl eval` `plugin.rice_ornaments = { corner; size; reach;
  inactive }` from `widgets.ornaments.settings` (corner = assets root +
  path), or `corner = ""` (off) for a theme without them. Never fatal.
  It runs at start, on every `config.reloaded` (a reload resets plugin
  options to defaults; the plugin's own init reloads the config too) and
  on every switch.
- The plugin now takes the theme's corner SVG directly: it renders it at
  twice `size` through hyprgraphics and mirrors it with cairo for the
  other three corners, so no PNGs are built.
- The shell overlay (D-074) stands down while the plugin is loaded:
  `OrnamentController` asks the same question at start and on each
  `configreloaded` event. If the plugin is missing (a broken build, an
  unload), the overlay draws again.
- Tests: the switch test mocks the plugin list and asserts the options
  appear only when the plugin is loaded, `corner = ""` on Cyberpunk, and
  nothing without the plugin. End to end in a nested Hyprland: config
  load, the built adapter with the built LoTM manifest, corners drawn.
- Recovery: `hyprctl plugin unload <path>` removes it live (the overlay
  returns on the next reload); dropping the `plugins` line removes it
  from the config.
- Why: the compositor knows where every window is on every frame.

### D-081 — The shell's panels wear the window frame

- Date: 2026-11-20 · Status: active · Amends D-076
- The user's call: the launcher and the other shell panels should have
  the same border and corner pieces as the windows.
- `widgets.plates.settings.<role>` may be `"window"`. `PlateFrame` then
  draws the window frame: a `bg.mantle` fill inside a
  `tokens.chrome.border.width` border in `accent.primary`, with the
  `widgets.ornaments` corner piece in each corner, placed as the plugin
  places them (the frame's outer corner at the piece's `(reach, reach)`).
  The border sits `reach` inside the surface, so panels that clip keep
  their corners whole. A surface may set `rule` for an alert colour.
- `PlateFrame` now also frames the theme switcher, wallpaper picker,
  satchel and polkit prompt, as well as the launcher, dashboard and
  notification centre. Do-not-disturb turns the centre's border amber;
  a polkit error turns the prompt's red.
- LoTM: `plates.panel = "window"`; `bar/panel.svg` is removed. Toasts keep
  the riveted plate, since 48 px corners crowd a single line.
- Verified: headless shots of the launcher, dashboard, switcher and
  notification centre in the frame; checks and build.
- Why: one frame for everything that opens over the desktop.

### D-082 — Toasts are letters: sealed, opened on parchment, burnt away

- Date: 2026-11-20 · Status: active · Extends D-056, D-081
- The user's call: toasts should feel impressive, "like a letter with a
  red seal being opened and then burning up when going away", on
  parchment in a Victorian hand, in the full window frame.
- `widgets.correspondence.settings.ceremony = { paper?; ink?; wax?;
  ember?; seal?; hand?; print?; }` opts a theme in, validated with closed
  keys and five must-fail cases. With it, every toast is a letter:
  - Arrival: a sealed envelope fills the window frame (the paper aged
    and warmed toward the wax), its flap closed with a wax seal pressed
    with `seal`. It is held a moment, the flap lifts, the envelope falls
    away, and the message lies on `paper` (darkening toward its foot and
    edges), each step at the ceremonial pace (`Motion.ritualAssemble`).
  - The letter: the app name in the display face's small caps, the
    persona's label beside it, the summary in `hand` (up to two lines),
    the body in `print` italic, all in `ink`; the broken seal beside it.
    Urgent letters keep a red seal and a red frame.
  - Departure: on expiry or a click, the letter burns away from its
    bottom edge along a ragged front, charring ahead of an ember line in
    `ember`: `components/effects/BurnEffect`, a layer effect with a new
    `burn.frag` (compiled with the other shaders). Without the compiled
    shader (dev runs) or with motion reduced, it fades on `Motion.fade`.
    Toasts used to vanish at once; every toast now leaves through
    `leave()`.
  - Letters stay 7.5 s (urgent 8 s, others 5 s).
- `plates.toast` may be `"window"` (D-081); `PlateFrame` gains `fill`.
  Persona letters without a ceremony keep their small envelope card.
- LoTM: `paper = fg.primary` (parchment), `ink = bg.sunken`, `wax =
  accent.tertiary` (ritual crimson), `ember = state.warn`, the Fool's
  sigil in the wax, Pinyon Script for the hand and IM FELL English for the
  print (both in the installed Google Fonts); toasts wear the window
  frame. `bar/toast.svg` is removed.
- Verified: headless shots with the compiled shader of the sealed
  envelope, the opening, the letter and four frames of the burn; plain
  toasts unchanged without a ceremony; checks and build.
- Why: a notification is correspondence in this world; it should arrive
  like a letter and leave no trace.

### D-083 — Burning letters throw sparks and crackle

- Date: 2026-11-20 · Status: active · Extends D-082, D-057
- The user's call: add sparks and a burn sound to the burning toasts.
- Sparks: while a letter burns, a spark is thrown every 40 ms from a
  random point along the burn front (its height follows `burn.frag`'s
  rise term). Each is a hot core in a soft `ember` halo that rises 36–92
  px, drifts sideways, shrinks and cools over 0.65–1.15 s, then removes
  itself. They live in a layer above the letters, so they outlive the
  paper; the toast window keeps 72 px of headroom above the stack
  (input masked to the letters) and stays up until the last spark is out.
- Sound: a new cue, `letter-burn`, plays as a letter catches (muted by
  default like every cue, and per-cue silenceable). LoTM's is rendered
  from `assets/sounds/src/letter-burn.sh`: a soft brown-noise roar as the
  paper takes, a bright hiss, and sparse crackles, dying out over 1.7 s.
- The burn itself now takes 2 s (three times the ceremonial duration,
  at least 2 s), so the front can be watched climbing.
- Verified: headless frames of the burn with sparks rising and lingering
  past the letter; checks and build.
- Why: fire should leave something in the air.

### D-084 — The lock is Chanis Gate

- Date: 2026-11-21 · Status: active · Extends D-037 · Phase 2 of the
  Threshold, Gate and Vigil brief
- The LoTM lock variant's backdrop is a painted scene, not a video: the
  user generated `lockscreen/lotm/gate/base.png` (2912×1632, Midjourney,
  from prompts in this session), the black iron gate under the cathedral
  with the seven medallions. `RICE_LOTM_LOCK_SCENE=video` brings back the
  theme's video, which stays in the theme as an opt-in.
- `lockscreen/lotm/GateScene.qml` brings the still to life. Every
  position is in the image's own pixels (measured at 1456×816), so it
  holds at any size; wide screens crop to cover, tall ones fit the
  whole image over a blurred, dimmed copy.
  - Candle light flickers on both sconces; a faint moonlight band
    crosses the gate once a minute. Both pause after 30 s without input
    or pointer movement.
  - One medallion lights per typed character (outer pairs first, the
    moon last) as a halo that leaves the emblem readable.
  - A refused passphrase drains the medallions, flares the lock plate
    red and rattles the leaves; the message reads "THE GATE HOLDS".
  - On success every medallion blazes, the interface fades, and the two
    leaves (the still, masked to each half of the arch) swing inward on
    their hinges onto warm light, then the scene fades to black.
  - 20:00–06:00 the crypt is graded colder and darker, the candles lower
    and the medallions faintly alive; the opening light is not graded.
- Main.qml: in gate mode the name and passphrase sit centred under the
  lock plate ("SPEAK THE WORD"); the clock and power row keep their
  places. It exposes `unlockDuration` (1.3 s).
- Runtime: `ThemeLock` keeps the loaded theme item and, after a
  successful login, holds the session lock for the theme's
  `unlockDuration` (at most 1.5 s, at least the old 60 ms) before
  releasing it, so the gate opens while the session is still locked.
  The preview host accepts `RICE_LOCK_PREVIEW_ACCEPT=<word>` as a success
  so an unlock can be watched; nothing is unlocked there.
- Cost: one image and a few small animated items, idle after 30 s,
  where the video decoded on every output for the whole lock.
- Verified: headless preview runs (a FloatingWindow copy of the preview
  host): the scene at rest, lit medallions, the denial, and four frames
  of the opening; lint and build. The real lock is seen on next lock.
- Why: the user wanted the lock to be the Gate, hyperreal or painted, and
  cheaper than a video.

### D-085 — The ascent to Sefirah Castle

- Date: 2026-11-21 · Status: amended by D-086 (the ascent moved to login) · Extends D-044, D-053, D-077 · Phase 3
  of the Threshold, Gate and Vigil brief
- The user generated two images in Midjourney from prompts written in this
  session: `assets/boot/ascent.png` (1536×3072), dark fog rising through a
  glowing vortex to the palace above it, and `assets/boot/hall.png`
  (2912×1632), the palace hall down its length to the empty seat and the
  door of light.
- `integration.boot.ascent = { climb; hall; }` (paths, `.png`/`.jpg`,
  validated with closed keys and four must-fail cases). The splash
  builder scales the climb to 1024 px wide and the hall to 1600, and
  quantizes both to 256 colours with pngquant: about 1.8 MB together, since
  every generation's initrd lands on the EFI partition (63 MB free on
  shitbox). `rice-boot` checks both ship.
- The script (`ascent = 1`): once the passphrase is taken (or, with no
  prompt, past half of boot progress), the sigil, ring and glow give way
  and the view climbs the tall image from its foot to its top, the fog
  banks lifting and thinning, then the hall fades in. Its pace is the
  further of about 4 s and the remaining boot progress, so it arrives
  before the splash quits. A wrong passphrase brings the prompt back and
  resets the climb. Shutdown and reboot run it backwards on the script's
  clock (about 5 s), from the hall down into the fog and the sigil.
- Login: `widgets.awakening.settings.backdrop` puts an image under the
  fog-lift; LoTM's is the hall, so the session opens on the place the
  splash arrived in and the fog lifts it away. Its words get a shadow over
  a backdrop. The awakening settings now have closed validation (title,
  subtitle, hold, lift, sound, backdrop) and four must-fail cases.
- The user also made a short hall video (`assets/boot/hall.mp4`, fog
  drifting, camera still). It is not wired in: the shell does not load
  QtMultimedia (D-057), so playing it would reopen that choice.
- Verified: checks and build; the awakening on the hall headless with
  compiled shaders. The splash script could not be run outside a real boot
  (`plymouthd` stalls in a user namespace), so it is reviewed, not run; the
  first boot is its test.
- Why: the passphrase is the threshold; what lies past it should be the
  place the Tarot Club meets.

### D-086 — The ascent moves to login; shutdown has no splash

- Date: 2026-11-21 · Status: active · Amends D-085, D-044, D-077
- After the first real boot the user reported: the boot images lagged
  badly (no smooth motion), shutdown and reboot hung on the sigil and ring
  until the power button was held, the sigil sat off-centre in a lumpy
  ring, and shutdown need not show anything.
- The ascent leaves Plymouth. Plymouth draws in software on every output,
  and a full-screen pan at 2560 px could not be smooth there.
  `integration.boot.ascent` and the script's climb are removed, so the
  splash is the sigil, ring, fog and prompt again (≈ 200 kB of images
  instead of 1.8 MB per initrd).
- The ascent is now the login reveal, drawn on the GPU: the awakening gains
  `climb` (an image under assets/). Once both images have loaded (at most
  1.5 s), the view climbs the tall image from its foot to its top over
  2.6 s, the `backdrop` hall fades in, and the words, hold and lift follow.
  LoTM: `climb = "boot/ascent.png"`, `backdrop = "boot/hall.png"`. One more
  must-fail case for `climb`.
- No splash on shutdown, reboot, halt or kexec:
  `plymouth-{poweroff,reboot,halt,kexec}.service` are masked in
  `hardware-base`. The reboot that hung reached systemd's final stage (the
  journal ends there) with only the splash on screen; without it the
  machine just turns off, and any hang there would show on the console.
- The ring is a clean circle under a soft blur. The turbulence
  displacement it had pushed the stroke about 1.5 % down and right and
  made it lumpy, so the sigil looked off-centre inside it.
- Verified: checks and build (the four Plymouth units link to /dev/null);
  the login climb headless, frame by frame, with compiled shaders.

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
  (Amended by D-064: a theme may opt into the bounded tray hatch.)
- **L-010** Widgets expose the descriptor contract and never import services
  (mechanism defined by D-009).
- **L-011** Clock keeps digits alongside the dial. Default bar height 56px,
  configurable per theme.
- **Rejected ideas** (do not re-litigate without a superseding entry): full Hyprland
  Lua rewrite; permanently animated UI elements; full systray exposure in the bar;
  per-widget independent floating popouts.
