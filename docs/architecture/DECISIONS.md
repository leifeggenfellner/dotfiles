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

- Date: 2026-07-07 · Status: active
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

### D-032 — The dock is an optional app-launch surface

- Date: 2026-07-09 · Status: active
- The dock is a runtime-owned surface, enabled only by ordinary
  `widgets.dock.settings` data. Themes provide a bounded list of app match specs
  and optional labels; the runtime resolves those specs through `AppsState` and
  launches through the same command path as the launcher.
- Dock presence is not core shell state. Unconfigured themes do not map a dock,
  and configured themes may choose focused-monitor or all-monitor placement. The
  dock may show theme-provided labels as hover affordances, but it must not own
  pinned-app persistence or bind directly to `DesktopEntries` internals.
- Why: a dock is useful daily chrome, but it should remain an optional surface on
  top of the existing app service rather than a second launcher model.

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

- Date: 2026-07-09 · Status: active
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
