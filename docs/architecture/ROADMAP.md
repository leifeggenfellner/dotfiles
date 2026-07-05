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
  swaync must own org.freedesktop.Notifications. Still missing for full parity:
  actions, inline reply, urgency styling, DND.

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

## Phase 9 — Second theme (validation) ⬜

One theme only (pokemon or cyberpunk, not both), data-first. Purpose: prove the
contract; fix what it breaks.

## Phase 10 — Rice switcher ⬜

- Two-layer switch machinery (D-003): all-themes build + `themes.json` index,
  `$XDG_STATE_HOME/rice/active` pointer, `rice-switch` tool, live re-bind,
  wallpaper orchestration, switcher UI with `preview.png`.

## Later surfaces (slot in after Phase 6, order by appetite)

Volume/brightness OSDs · media controls (MprisState) · power menu · clipboard
history · wallpaper picker · dashboard widgets (system monitor, weather, dev
widgets) · optional dock · LOTM plugin widgets (tarot/ritual — proves the plugin
contract) · ambient effects tier (Phase 4+ of `contracts/motion-contract.md`).

## Deferred / future

- HM specialisations per theme for full live-switch fidelity — only if
  post-switch chrome lag proves annoying (D-003).
- Themes as external flakes (`rice.themes.<name>.package`).
