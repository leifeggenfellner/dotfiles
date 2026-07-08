# Rice Framework — Roadmap

Vertical-slice ordering (D-014): build a minimal LOTM desktop first, extract the
framework from working code. Only generalize what already exists in the slice —
never speculate abstractions. The legacy bar (`modules/programs/quickshell/ui/`)
keeps running until the new shell reaches parity (Phase 8).

A task is done only when it runs, is wired into the shell (if UI), and leaves no
fallback hacks behind. Status: ⬜ pending · 🔄 in progress · ✅ done.

## Phase 0 — Branch ✅

Branch `feature/rice-framework-v0` off `rice/lotm-foundation`.

## Phase 1 — Greenfield runtime skeleton 🔄

Goal: Hyprland → Quickshell → something stable on screen. Structure, not features.

- Runtime tree at `modules/rice/runtime/quickshell/` (final location per D-007):
  `shell.qml` + `core/` (static-value `Theme`, `ShellState` with IPC toggles) +
  empty surfaces (`bar/TopBar`, `launcher/`, `dashboard/`, `osd/`,
  `notifications/`) + MOCK services (`NetworkState`, `AudioState`,
  `BluetoothState`, `WallpaperState`, `NotificationState`) following the
  service-contract shape.
- `scripts/rice-lint.sh` (import allowlist + theme-literal ban) in
  `nix flake check` from day one (D-015).
- Exit: shell launches next to old bar; IPC visibly toggles empty regions;
  `Theme.*` readable everywhere.

## Phase 2 — Launcher MVP (vertical-slice anchor) ⬜

- Opens/closes via Super+Space (one hyprland.nix keybind → `qs ipc`), Esc,
  click-outside; static dummy app grid; styled via `Theme.*` only; simple inline
  open/close transition (deliberately local — Motion extracts it in Phase 3).
- Exit: key → opens → closes smoothly; zero hardcoded style values.

## Phase 3 — Motion v1 ✅

- ✅ `core/Motion.qml` — semantic specs (`panelOpen`, `panelClose`, `stateChange`)
  resolved from Theme motion tokens (D-010); collapse to 0ms when motion is off.
- ✅ `core/MotionAnim.qml` — the one animation primitive (fade/scale/slide are the
  property it's attached to, not separate types).
- ✅ All surfaces migrated: launcher (fade+scale), dashboard (fade+scale),
  notification center (slide+fade), OSD (fade + animated value bar).
- ✅ Debug overlay (`modules/debug/`) — theme source, surface flags, service
  states, overlay FPS; toggled via `shell toggleDebug`. Paid for itself on day
  one (diagnosed the focused-monitor bug).
- ✅ Early partial-real `services/hypr/HyprState.qml` (native Hyprland binding,
  D-008 tier 1): `focusedScreenName` drives launcher focused-monitor-only
  visibility. Note: compare monitors by NAME — `HyprlandMonitor.screen` is
  unreliable on Quickshell 0.2.1.
- Exit criterion verified: zero inline animation parameters outside `core/`.

## Phase 4 — Theme system v1 (LOTM only, structured) ✅

- ✅ `modules/rice/themes/lotm/_theme.nix` — real manifest source: LOTM palette
  (umber/parchment/antique-gold/fog/crimson), typography, metrics, motion,
  icon overrides. Ends the D-014 static-Theme waiver.
- ✅ `core/ManifestLoader.qml` — sole manifest reader; theme-neutral defaults
  deep-merged under the file; watches the file → live re-theme on edit.
  Path: `$RICE_MANIFEST` env (dev) → `~/.config/rice/manifest.json`.
- ✅ `core/Theme.qml` rewired to manifest tokens; adds `icon()` resolution.
- ✅ Semantic icon system (D-016): `components/Icon.qml` renders glyph or theme
  image file; launcher + OSD migrated to icon names; LOTM ships hand-drawn
  sigil SVGs (settings seal, watcher's eye) in `assets/icons/`.
- ✅ Minimal Nix wiring: `modules/rice/nix/manifest.nix` HM module serializes
  the active theme to `rice/manifest.json` (validation/index remain Phase 7).
- Exit verified: recoloring the desktop is a one-file edit in the theme dir,
  live-reloaded; no style or icon literals in surfaces.

## Phase 5 — Services v1 (real OS integration) ⬜

Replace one mock at a time, porting from the legacy implementations in
`modules/programs/quickshell/ui/services/` where they exist — preferring native
Quickshell APIs / DBus over their current CLI polling (D-008). Order:

1. ✅ WallpaperState — watches the shared persist file
   (`~/.config/wallpaper/current`), `setWallpaper` runs the same awww command
   as wallpaper-restore. Note: the command path has no UI caller yet — first
   exercised by the wallpaper picker surface.
2. ✅ AudioState — `Quickshell.Services.Pipewire` (`Pipewire.defaultAudioSink`
   with `PwObjectTracker`); verified live against wpctl. No polling.
3. ✅ NetworkState — event-driven nmcli (D-008 tier 3, justified: no native NM
   module, no QML DBus): long-lived `nmcli monitor` stream + 400ms debounce,
   zero polling; escape-aware field parser; connect/disconnect/rescan commands.
   Caveats: connect/disconnect have no UI caller yet (first exercised by the
   network popout); no auto-recovery if NetworkManager restarts (available
   flips false; shell restart recovers).
4. ✅ BluetoothState — native `Quickshell.Bluetooth` (tier 1): live
   BluetoothDevice objects (paired/connected filter), adapter power command,
   connect/disconnect by address. bluetoothctl eliminated.

Services expose a `mock: bool` flag; the debug overlay tags each row
MOCK / live / n-a from it.

Phase 5 complete (2026-07-03): all system services real except
NotificationState (Phase 6 by design). Command paths without UI callers are
listed above and get exercised as their surfaces land.

## Phase 6 — Notification Center ✅ (swaync handoff pending)

- ✅ `NotificationState` real on Quickshell's `NotificationServer` (D-008
  tier 1): tracked notifications in the mock's wrapper shape (UI unchanged),
  `dismiss`/`clearAll`, `received(entry)` signal. Gotcha recorded: tracked-model
  insertion is async — arrival consumers get the entry ON the signal, they must
  not look it up.
- ✅ Toasts surface: top-right stack, auto-expire (5s), click-to-dismiss,
  Motion fade, capped depth. Center gains clear-all.
- ⬜ swaync handoff: swaync stays the daemon until the shell autostarts
  (Phase 7) — one notification daemon at a time. When the shell isn't running,
  swaync must own org.freedesktop.Notifications. Phase 16 closes the parity
  backlog: actions, inline reply, urgency styling, and DND.

## Phase 7 — Nix integration layer ✅

- ✅ `mkThemeManifest` (`modules/rice/nix/_manifest-lib.nix`): validates the
  closed-core token schema, meta, icon files, raster sources at eval — a broken
  theme fails `nixos-rebuild`/CI with a precise message, never the running shell.
- ✅ Raster pipeline (D-011): theme-declared `assets.rasterize` renders SVGs to
  PNG at build (resvg); manifest exposes `assets.raster.<name>`. LOTM pathway
  SVGs → 22×64px PNGs. (Correction, D-017: `pathways_png/` turned out to be
  authored color art, not derived rasters — it stays; the pipeline serves true
  silhouette cases.)
- ✅ Runtime installed as named Quickshell config `rice`
  (`~/.config/quickshell/rice`); `rice-shell` launcher (prod/dev modes, kills
  only rice instances); autostart via Hyprland exec-once under `rice.enable`.
- ✅ Keybinds: Super+Space launcher, Super+N center, Super+Sec+Ter+N clear-all —
  all via `quickshell -c rice ipc`; swaync binds retained on non-rice hosts.
- ✅ swaync handoff: `services-swaync` disabled when `rice.enable` — the shell
  owns org.freedesktop.Notifications from next rebuild.
- Old `theme.json` generation retires with the legacy bar (Phase 8), which
  still consumes it.
- Still one theme; switching remains the config value (machinery is Phase 10).

## Phase 8a — Generalization: widget system ✅

- ✅ Widget contract implemented: `widgets/WidgetDescriptor.qml` (widgetId,
  contractVersion, region, priority, monitorPolicy, services, settings,
  glance/popout) + `widgets/Registry.qml` — surfaces render only from the
  registry; manifest `widgets.<id>` overrides placement/settings (L-001).
- ✅ Service injection real (D-009): TopBar resolves declared service ids to
  singletons; widgets never import services.
- ✅ Three widgets, theme-neutral names: `WorkspacesGlance` (identity 100% from
  theme settings, numeric fallback when unconfigured), `ClockGlance`
  (Quickshell SystemClock, no timers), `SystemClusterGlance` (network/audio/
  battery glance).
- ✅ The LOTM pathway catalog is now pure theme data
  (`widgets.workspaces.settings.items` — authored `pathways_png/` emblem icons
  per D-017, plus colors + labels).
- ✅ `Theme.assetUrl` resolver (`raster:<set>/<file>`, absolute, root-relative)
  and `Theme.widgetConfig(id)`. PowerState real via native UPower (note:
  `UPower.ready` does not exist on 0.2.1 — guard with device properties).
- TopBar stays hidden by default until 8b retires the legacy bar.

## Phase 8b — Generalization: parity + retirement 🔄

- ✅ Single-open popout system (L-002): `ShellState.activePopout` +
  `modules/bar/BarPopout.qml` — anchored below the bar aligned to the widget's
  region, click-outside + Esc close, service injection like mounts, IPC
  `shell togglePopout <id>` for scripting/testing.
- ✅ System cluster popout: volume slider + mute (live Pipewire), wifi list
  with connect/disconnect/rescan, bluetooth power + device connect.
- ✅ Power widget (glance + menu popout): Lock/Logout/Reboot/Shutdown via new
  `SessionState` service — legacy power menu parity.
- ✅ Inline wifi password prompt: NetworkState maps nmcli's secrets error to
  semantic `passwordNeededFor`; the row expands a masked input (Enter joins).
  Other errors collapse to one line; popout clears stale state on open.
- ✅ Tray inside the system popout (L-009, never bar icons): native
  `Quickshell.Services.SystemTray` via `TrayState`; click = activate.
  Context menus not exposed yet (backlog, Later surfaces).
- ✅ D-012 bridge: themes ship `palette.legacy` (derived from their tokens in
  `_theme.nix`); `modules/rice/nix/_legacy-palettes.nix` merges them into the
  classic palette registry; `rice-bridge` points `environment.desktop.theme.scheme`
  at the active rice theme. Accent trick: mauve/blue/sapphire map to the
  theme's accents, so default style options recolor with zero changes.
  GTK/Qt/hyprlock/Hyprland go LOTM at the next rebuild.
- ✅ Retirement: TopBar visible by default; `modules/programs/quickshell/`
  (legacy bar + old theme.json), `reload-bar`, `kill-bar-dev` deleted;
  exec-once runs only `rice-shell`; `kbar` alias repoints to rice-shell.
- Hard-won fact: `toString ./path` in flake eval DROPS string context — a
  manifest carrying such a path is not GC-protected. `mkThemeManifest` now
  interpolates (`"''${themeDir + "/assets"}"`), which also narrows the
  reference to just the assets dir.

Phase 8 complete (2026-07-06): the framework exists — descriptor registry,
injected services, themed popouts, tray, Nix bridge, single runtime tree.

## Phase 9 — Second theme (validation) ✅

One theme only (cyberpunk chosen over pokemon), data-first. Purpose: prove the
contract; fix what it breaks.

- ✅ `modules/rice/themes/cyberpunk/_theme.nix` — deliberately data-ONLY
  manifest: neon token set, Orbitron/Chakra Petch typography, hard radii,
  snappier motion durations, glyph-only icon overrides, glyph workspace
  identities, `palette.legacy` bridge entry. Zero asset files, zero plugins.
- ✅ Contract gap found and fixed (the phase's purpose): `WorkspacesGlance`
  rendered identity icons only as images, so a data-only theme couldn't
  express workspace identity. The widget now applies the D-016 heuristic to
  `settings.items[].icon` — "/" means assetUrl image, anything else is a font
  glyph tinted with the item's color. Additive, widget-owned schema; no
  contract text change needed (widget-contract leaves settings widget-defined).
- ✅ Nix wiring: `cyberpunk` in the `rice.theme` enum; legacy palette entry in
  `_legacy-palettes.nix`. The stale pre-contract pokemon scaffold (README-only,
  described a structure the contract replaced) retired along with its dead
  enum entry and asset-dir options.
- Verified: both manifests build via `mkThemeManifest`; `rice-lint` clean;
  shitbox system evals with either theme active (D-012 scheme follows);
  12s live shell smoke test per theme (`RICE_MANIFEST` dev path) — zero QML
  errors on both, confirming the glyph arm and the unchanged image arm.
- Still open (by design): no wallpapers/preview.png yet — those become
  meaningful with the Phase 10 switcher.

## Phase 10 — Rice switcher ✅

- Two-layer switch machinery (D-003), concretized as D-018:
- ✅ `mkThemeIndex` (`modules/rice/nix/_index-lib.nix`): builds every theme
  under `themes/`, installs `~/.config/rice/themes.json` (displayName,
  manifest, preview, wallpapers per theme — all store paths). Previews:
  authored `assets/preview.png` wins; otherwise a token-swatch card is
  derived at build with ImageMagick (D-011). `meta.preview` removed from the
  contract before any theme used it.
- ✅ `rice-switch` (`modules/rice/nix/switch.nix`): validates against the
  index, atomic pointer write to `$XDG_STATE_HOME/rice/active`, wallpaper
  orchestration (first theme wallpaper via the shared awww flow — dormant
  until themes ship wallpapers), IPC nudge `rice reload` for the
  pointer-file-creation case.
- ✅ Live re-bind: `ManifestLoader` resolves `$RICE_MANIFEST` → pointer via
  index → default `manifest.json`, watching all three files; IPC
  `rice active` exposes the resolved theme for scripting/tests.
- ✅ Switcher UI: `modules/switcher/ThemeSwitcher.qml` — preview cards from
  `Theme.catalog`, active ringed, click switches via new `RiceState` service
  (runs rice-switch; pointer/index knowledge stays in core). Super+T /
  `shell toggleSwitcher`; mutually exclusive with launcher/dashboard.
- Verified: index + previews build; home generation builds; rice-lint clean;
  sandboxed-HOME live test — shell resolves pointer at startup, `rice-switch`
  re-binds the running shell via the file watch alone (<2s), bogus names
  rejected; switcher screenshot confirms themed cards + active ring.
- Requires a rebuild to land on the host (themes.json, rice-switch, keybind).

## Phase 11 — Per-theme wallpapers + wallpaper switcher ✅

Each rice owns its wallpaper set; browsing/cycling stays inside the active
theme's set. Concretized as D-019.

- ✅ Build-time glob: `mkThemeManifest` enumerates `assets/wallpapers/`
  (png/jpg/jpeg/webp, natural-sorted) into `assets.wallpapers` as store paths
  sharing the assets-dir store copy; missing dir → `[]`; themes never
  hand-list (contract's "required ≥1" amended). Index inherits it. Seeded:
  lotm (golden_fog, misty_mountains), cyberpunk (rain_night).
- ✅ `services/prefs/PrefsState.qml` — sole writer of
  `$XDG_STATE_HOME/rice/prefs.json` (`{ schemaVersion, wallpapers.<theme> }`),
  theme-blind (theme name passed in by callers), FileView setText +
  atomicWrites. Concretizes ARCHITECTURE state category 3.
- ✅ `modules/wallpapers/` — `WallpaperCommands` (module-layer singleton, the
  single apply path: setWallpaper + recordWallpaper together; first real UI
  caller of the Phase 5 command path), `WallpaperIpc` (`wallpapers next`),
  `WallpaperPicker` surface (active theme's grid, current ringed, next
  button, empty-state text; fourth mutually-exclusive center-stage surface).
- ✅ rice-switch restores the theme's remembered wallpaper (stale store path
  re-matched by basename) else `wallpapers[0]`, else keeps current; reads
  prefs, never writes.
- ✅ Keybinds: Super+W → picker on rice hosts (fzf wallpaper-picker moves to
  the non-rice branch), Super+Alt+W → cycle.
- Bug found by the sandbox test and fixed: `WallpaperState`'s persist-file
  watch never fired when the file was created by our own first write (watch
  on a missing file, same gotcha as D-018's pointer) — now reloads explicitly
  after a successful apply.
- Verified: index/manifest builds (incl. synthetic empty-wallpapers theme),
  rice-lint, home generation; sandboxed live loop — cycle wraps within the
  theme, prefs.json created and updated only on user apply, switch cyberpunk
  → lotm restored the remembered (non-first) wallpaper; screenshot confirms
  the themed grid with current-wallpaper ring. Requires a rebuild to land.

## Phase 12 — Live lockscreen theming ✅

Concretized as D-020: the lockscreen joins the rice at lock time.

- ✅ hyprlock.conf declares `$rice_*` hyprlang variables (12 colors + 2
  fonts) with rebuild defaults from the D-012 bridge; the spec lives once in
  `modules/programs/_hyprlock-vars.nix`, shared with the lock-screen script.
- ✅ `lock-screen` resolves pointer → index → active manifest (read-only) and
  rewrites the variable lines: legacy palette → `rgba(hex+alpha)`, display/
  mono fonts (LOTM locks in Cinzel, cyberpunk in Orbitron). `--print-config`
  dry-run flag for testing.
- ✅ New optional `assets/lockscreen/` role (globbed like D-019 wallpapers via
  the generalized `globImages`): lock background precedence = theme lockscreen
  asset → live wallpaper → baked. LOTM ships a 4K Klein/Backlund still
  (derived from authored video — hyprlock cannot render video) and the four
  extracted frames joined its wallpaper set.
- ✅ Latent bug fixed: the script's monitor/wallpaper seds matched
  `key = value` but HM emits `key=value` — both had been silent no-ops
  (lockscreen never followed the live wallpaper). Now whitespace-tolerant
  EREs.
- Verified: home generation builds; generated conf has vars before sections
  and only expected diffs; sandboxed dry-runs — lotm → gold/Cinzel/Klein
  lockscreen, cyberpunk → cyan/Orbitron/live wallpaper, bogus pointer →
  index default, missing index → defaults byte-stable, monitor sed fires and
  leaves the background's empty `monitor=` alone. Real-lock check after
  rebuild: `rice-switch cyberpunk` + lock → cyan/Orbitron without rebuild.

## Phase 13 — Motion v2 + ambient foundation ✅

Concretized as D-021 (ambient effects engine) and D-022 (motion v2). First
phase of the LoTM immersion plan: capability systems before content — the
runtime gains atmosphere machinery; LOTM opts in as pure data.

- ✅ Manifest easings honored: `Theme` resolves named curve strings
  (warn-and-default OutCubic); they had been contract-declared but ignored.
  Optional `durations.ceremonial` (defaults to slow). Validation for both in
  `mkThemeManifest` — plus `tokens.effects` shape/type checks and the L-005
  token-ref-only tint rule (negative-tested: literal color and unknown layer
  type both fail the build with precise messages).
- ✅ Ambient engine: `core/Effects` (sole effects-config reader; structural
  budgets ≤4 layers/≤12 particles/opacity caps), theme-neutral T1 primitives
  `components/effects/{FogLayer,ParticleField,VignetteLayer}` (Canvas painted
  once, transform/opacity animation only), per-monitor
  `modules/ambient/AmbientLayer` (layer-shell Bottom, empty input mask,
  unmapped + Loader-unloaded when paused).
- ✅ Governor: `modules/ambient/AmbientController` — the one place run/pause
  policy lives — pushes `ShellState.{ambientActive,reduceMotion}` from
  PrefsState (new `motion` prefs block: reduce, ambient auto|off) +
  PowerState (battery ⇒ pause) + HyprState (new `anyFullscreen` via Wayland
  foreign-toplevel watchers, event-driven). IPC `ambient status|setMode|
setReduceMotion` for scripting/tests. `Motion.enabled` folds in
  reduce-motion; new `awaken` spec drives the bar's one-shot startup reveal.
- ✅ LOTM manifest: easings + ceremonial=700 + ambient=true + three layers
  (fog in fog-blue, gold ember motes, sunken vignette). Cyberpunk untouched —
  manifest evals byte-equivalent (no effects key; loader defaults fill in).
- Verified: rice-lint clean; both manifests build; sandboxed live run — zero
  QML warnings, `ambient status` truthful, reduce-motion and mode=off each
  pause and restore live, three `rice-ambient` windows on the bottom layer
  unmap to 0 on pause and remap on resume (hyprctl layers). Budget: ambient
  OFF = 0.0% CPU over 10s (contract steady-state holds); ambient ON = 8.1%
  of one core across 3 monitors (T1 continuous drift; acceptable for the
  opt-in tier — the Phase 20 shader path is the planned cheaper fog).
- Caveats: the fullscreen gate's live flip was not exercised (watchers attach
  and count correctly over real toplevels; flip is a property binding) — first
  fullscreen video will confirm. Fog drifts in from offscreen over ~1 min by
  design (roll-in beats pop-in; also hides governor restarts). Bug found by
  the smoke test: unqualified `requestPaint()` inside `Connections` is a
  ReferenceError — qualify with the Canvas id.

## Phase 14 — Launcher v2: the Summoning ✅

Concretized as D-023: surface-level settings reuse the existing widget config
namespace. The first daily-use center-stage surface is now real.

- ✅ `services/apps/AppsState.qml` wraps Quickshell `DesktopEntries` (native
  tier 1): exposes visible desktop apps, stable sorted rows, and the single
  `launch(app)` command path. Launcher UI no longer binds to `DesktopEntries`
  internals.
- ✅ First `utils/` resident: `Fuzzy.qml`, a pure side-effect-free matcher used
  by `AppsState.search(query, limit)`. Ranking covers app name, generic name,
  comment, id, startup class, categories, and keywords.
- ✅ `modules/launcher/Launcher.qml` replaced the dummy grid with search input,
  ranked card grid, mouse hover selection, keyboard navigation (arrows), Enter
  launch, Esc/click-outside close, and desktop icon rendering through
  `Quickshell.iconPath` with a semantic fallback.
- ✅ Motion wiring: `Motion.surfaceReveal`/`surfaceConceal` aliases preserve the
  Phase 13 behavior under the named Phase 14 vocabulary; `Motion.sealPress`
  drives the activation pulse and collapses under reduce-motion.
- ✅ LOTM configures the Summoning through `widgets.launcher.settings`
  (placeholder, epigraphs, result layout). Cyberpunk ships no launcher settings
  and therefore keeps the neutral launcher copy and behavior.
- Verified: editor diagnostics clean; `rice-lint` clean; `nix flake check`
  clean; LOTM manifest + theme index build; live dev shell with LOTM manifest
  loads with zero launcher QML/icon warnings; path-specific IPC opens/closes the
  launcher and responds (`ambient status`). Automated typed-launch smoke was
  attempted with a harmless temporary desktop entry, but the marker did not fire
  under the available Wayland automation; manual type/launch remains the final
  host check after rebuild.

## Phase 15 — Observatory + Vitals ✅

Dashboard stops being a placeholder: it is now the Observatory, a descriptor-
driven surface for real system vitals and flavor panels.

- ✅ `services/system/SystemStatsState.qml` — real Linux vitals service: CPU
  deltas from `/proc/stat`, memory from `/proc/meminfo`, root disk usage, and
  first valid hwmon temperature. This is the deliberate D-008 tier 4 exception:
  one short 3s poll because aggregate load/memory/disk/temperature have no
  native event source in Quickshell.
- ✅ `widgets/meters/SystemMetersDashboard.qml` — built-in dashboard widget with
  four vial-style meters and real numbers always visible: CPU %, memory %,
  temperature °C or `n/a`, and disk %. Danger thresholds tint only the affected
  meter border/fill (the corruption-edge styling); no dashboard-wide alarm.
- ✅ `widgets/epigraph/EpigraphDashboard.qml` — generic flavor-text widget fed
  entirely by settings. Themes with no settings get neutral Observatory copy.
- ✅ Dashboard compositor migrated to the registry: `Dashboard.qml` renders
  `Registry.byRegion("dashboard")`, injects `systemStats`, closes on Esc or
  click-outside, and only appears on the focused monitor. Widget contract text
  now names `dashboard` as a surface-defined region.
- ✅ Keybind: on rice hosts Super+D now toggles the dashboard; non-rice hosts keep
  the old wofi binding. LOTM configures Observatory epigraphs and Beyonder meter
  labels/colors through `widgets.epigraph.settings` and `widgets.meters.settings`;
  Cyberpunk gets the plain widgets with no theme changes.
- Verified: editor diagnostics clean; `rice-lint` clean; LOTM manifest + theme
  index build; live dev shell with LOTM manifest loads, opens/closes the
  dashboard through path-specific IPC, and reports no Phase 15 QML/runtime
  warnings. Initial `nix flake check --print-build-logs` was blocked by the
  pre-existing `statix` warning in `modules/programs/vscode.nix`; that blocker
  was fixed immediately after Phase 15 and the full flake check passed.

## Phase 16 — Sound v1 + Gramophone + Correspondence ✅

Concretized as D-024: sound is event-bound and default-muted, media is native
MPRIS, and the notification parity backlog is closed in the Quickshell runtime.

- ✅ `core/Sound.qml` — semantic sound facade, gated by `ShellState.soundMuted`,
  playing theme assets through the Nix-owned `rice-sound-play` wrapper. Durable
  pref lives in `PrefsState.sound.muted` (default true) and is bridged by
  `modules/sound/SoundController`; IPC `sound status|setMuted|toggleMuted|test`.
- ✅ LOTM `assets/sounds/` — two small original WAV cues (`sealed-letter.wav`,
  `red-seal.wav`) mapped as `assets.sounds.notification` and
  `notification-critical`. Cyberpunk remains unchanged and therefore silent.
- ✅ `services/mpris/MprisState.qml` — Quickshell native MPRIS wrapper selecting
  the playing client when present; exposes track metadata/progress and
  play/pause/previous/next/seek commands.
- ✅ `widgets/media/` — Gramophone built-in (bar glance + popout) registered via
  the descriptor registry and injected with `mpris`. LOTM configures labels via
  `widgets.media.settings`; default themes get neutral copy.
- ✅ Correspondence upgrade: `NotificationState` now exposes actions, inline
  reply metadata, image/app metadata, urgency, and invoke/reply commands. The
  center renders letter-styled cards with urgency strips, action buttons,
  inline reply fields, dismiss/clear, and a durable DND toggle
  (`PrefsState.notifications.dnd`). Toasts respect DND and only play sound after
  a visible toast is appended.
- Verified: editor diagnostics clean for changed QML; `rice-lint` clean;
  LOTM manifest + theme index build; `nix flake check --print-build-logs`
  clean; live dev shell with LOTM manifest loads, opens/closes the Phase 16
  surfaces through IPC, and reports no Phase 16 runtime warnings beyond the
  known notification-owner/portal warnings in an already-running desktop.

## Phase 17 — The Artifact Satchel ✅

Concretized as D-025: clipboard history becomes a first-class center-stage
surface, with sealed entries persisted through PrefsState extras.

- ✅ `PrefsState.extra(namespace, key, fallback)` and `setExtra(namespace, key,
value)` add the generic namespaced extras bucket without changing the
  prefs.json sole-writer rule. First namespace: `satchel.sealed`.
- ✅ `services/clipboard/ClipboardState.qml` wraps `cliphist` with event-triggered
  commands: list on surface open, decode/copy on activation, delete on request.
  The long-lived watcher remains Hyprland's existing
  `wl-paste --watch cliphist store` process.
- ✅ `modules/satchel/Satchel.qml` — Super+V surface with search, keyboard
  selection, Enter to copy, `P` to seal/unseal, Delete/Backspace to forget, and
  artifact-card styling. It follows the same focused-monitor, Esc, click-outside,
  and mutual-exclusion pattern as launcher/switcher/wallpapers.
- ✅ Nix wiring: `cliphist` and `wl-clip-persist` are installed for Hyprland
  hosts; rice hosts bind Super+V to `shell toggleSatchel`. LOTM configures the
  Artifact Satchel title, placeholder, empty state, and sealed label through
  `widgets.satchel.settings`; Cyberpunk gets neutral defaults.
- Verified: editor diagnostics clean for changed QML/Nix; `rice-lint` clean;
  LOTM manifest + theme index build; `nix flake check --print-build-logs`
  clean; seeded `cliphist` with a harmless entry and live-smoked Satchel through
  IPC using the built LOTM manifest. Because `cliphist` was not in the current
  user PATH before rebuild, the smoke prepended the Nix store `cliphist` bin;
  the Home Manager package addition makes that permanent after rebuild.

## Phase 18 — Ritual & Divination Dressing ✅

Concretized as D-026: delegate slots are runtime-owned visual variants, not theme
behavior overrides, and divination panels are ordinary dashboard widgets fed by
injected services.

- ✅ Power-menu delegate slot: `PowerMenuPopout` keeps the default linear list for
  unconfigured themes and adds a known `radial` delegate selected by
  `widgets.power.settings.delegate`. Both delegates call the same injected
  `SessionState` actions, so the LOTM ritual circle is visual dressing only.
- ✅ `Motion.ritualAssemble` adds the ceremonial motion name used by the radial
  power delegate and collapses under the existing reduce-motion governor.
- ✅ `services/weather/WeatherState.qml` owns weather and sky state: hourly/on-
  demand wttr.in current conditions when curl/network are available, graceful
  fallback errors when absent, and local moon phase via `utils/Moon.qml`.
- ✅ `widgets/divination/WeatherDashboard.qml` and `CalendarDashboard.qml` extend
  the Observatory through the descriptor registry with injected `weather` data.
  The calendar panel shows real date data plus local lunar phase/illumination.
- ✅ LOTM manifest configures the ritual labels, weather/calendar panel copy, an
  authored `assets/preview.png`, and completed semantic sigil icon overrides for
  power, calendar, moon, and weather roles. Cyberpunk remains unconfigured and
  therefore keeps default widgets/delegates.
- Verified: editor diagnostics clean for changed QML; `rice-lint` clean; LOTM
  manifest + theme index build; `nix flake check --print-build-logs` clean;
  live dev shell with the built LOTM manifest loads, opens/closes dashboard and
  power popout through path-scoped IPC, and reports no Phase 18 runtime warnings
  beyond the expected duplicate notification-owner/portal warnings in an
  already-running desktop.

## Phase 19 — Tarot Draw Plugin ✅

Concretized as D-027: theme plugins are validated source directories with entry
QML files, loaded fail-soft by the registry, and limited to injected services.

- ✅ Manifest plugin packaging: `mkThemeManifest` validates `plugins[].source`
  directories and `entry` files, serializes source directories as store paths,
  and keeps plugin-local assets available at runtime.
- ✅ Registry plugin loading: `Registry.byRegion()` now merges built-ins with
  ready plugin components from `Theme.plugins`; broken plugin components warn
  and skip without taking down the shell.
- ✅ `themes/lotm/widgets/TarotDraw/` proves the contract with a dashboard plugin
  that receives `prefs`, `theme`, and `motion` from the dashboard mount and
  persists one daily draw in `extras.tarotDraw.daily`.
- ✅ LOTM ships seven authored tarot face SVGs plus a derived-style card back,
  `Motion.cardFlip`, and `widgets.tarotDraw.settings` copy. Cyberpunk remains
  plugin-free and unchanged.
- Verified: editor diagnostics clean for changed QML/Nix/docs; `rice-lint`
  clean; LOTM manifest + theme index build; `nix flake check --print-build-logs`
  clean; live dev shell with the built LOTM manifest loads, opens/closes the
  dashboard through path-scoped IPC, instantiates `tarotDraw`, and reports no
  plugin-load errors or duplicate runtime singleton warnings beyond the expected
  duplicate notification-owner/portal warnings in an already-running desktop.

## Later surfaces (slot in after Phase 6, order by appetite)

Volume/brightness OSDs · optional dock · additional LOTM plugin widgets.
The ambient effects tier landed as Phase 13 (D-021).

## Deferred / future

- HM specialisations per theme for full live-switch fidelity — only if
  post-switch chrome lag proves annoying (D-003).
- Themes as external flakes (`rice.themes.<name>.package`).
