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

1. ⬜ WallpaperState (easy win; wraps the existing awww/wallpaper-restore flow)
2. ⬜ AudioState (port → `Quickshell.Services.Pipewire`)
3. ⬜ NetworkState (port legacy state machine)
4. ⬜ BluetoothState

Exit: ≥2 real services live behind unchanged UI.

## Phase 6 — Notification Center ⬜

- `NotificationState` goes real on Quickshell's notification server; the
  notification center surface renders it (list rendering, overlay, state).
- swaync retires only at parity — exactly one notification daemon at any time.

## Phase 7 — Nix integration layer ⬜

- `rice.theme = "lotm"` formally drives the runtime: manifest generation moves to
  `modules/rice/nix/manifest.nix` (`mkThemeManifest`, build-time validation),
  asset install pipeline (SVG→raster derivation, D-011), HM module points
  Quickshell at the new runtime; old `theme.json` generation retires.
- Still one theme; switching is just the config value.

## Phase 8 — Generalization pass (the framework is born) ⬜

Extract only what the slice proved:

- Theme contract → formal manifest v2 per `contracts/theme-manifest.md`.
- Widget registry + descriptor formalization; port remaining old-bar widgets
  (workspace indicator with theme-config icon sets — the LOTM catalog moves into
  the theme package per D-006, system cluster, clock) into the new tree with
  theme-neutral names.
- Service interface layer + asset resolver (`Theme.assets` roles).
- Legacy tree `modules/programs/quickshell/ui/` retires; rice-lint exemption ends.
- Rice manifest feeds the legacy HM `theme.colors`/`theme.style` bridge (D-012).

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
