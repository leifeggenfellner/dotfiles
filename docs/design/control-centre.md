# The Control Centre: bar popout rework brief

Status: **in progress**. Directions confirmed with the user on 2026-11-21.
Phase 1 (kit and Wi-Fi) landed as D-088.
When a phase lands, its decision goes into
`docs/architecture/DECISIONS.md` as a new D-number and this brief links to it.

## Why

The bar's popouts are hard to work with:

- **One long column.** The system popout stacks volume, Wi-Fi, Bluetooth
  and the tray. The only controls are small text links ("connect", "on").
- **Network is not reactive.** `NetworkState` runs `nmcli` and re-reads its
  output after each change. A row never says it is joining, a failure is one
  line at the bottom of the list, the list is cut at six, and there is no
  Wi-Fi switch and no way to forget a network.
- **Bluetooth only lists paired devices.** There is no scan, no pairing, no
  battery level and no feedback while a device connects.
- **Audio is one slider.** There is no output or input choice, no
  microphone and no per-app volume.
- **Tray menus are the apps' own** (D-036), so they break the theme.
- **No keyboard.** Nothing but Esc works without the mouse.

Quickshell 0.3.2 binds all of it natively: `Quickshell.Networking`
(NetworkManager, per-network state and failure reasons), `Quickshell.Bluetooth`
(discovery, pair, forget, battery), Pipewire (nodes, streams, peak levels),
UPower `PowerProfiles`, and `DBusMenu` for drawing tray menus ourselves. So
the rework is reactive end to end with no CLI in the loop (D-008 tier 1).

## Direction (confirmed)

- **A control centre with drill-in pages.** The system glance opens one
  popout. Its home shows quick toggles and sliders; a toggle with a chevron
  slides into a full page for that subject (Wi-Fi, Bluetooth, Sound, Power)
  with a back arrow. Power (session), the tray hatch and monitor profiles
  stay their own popouts.
- **Tray menus are drawn in the theme** (supersedes D-036 when it lands).
- **Everything in scope:** audio devices and app volumes, Bluetooth pairing,
  battery and power profiles, brightness and quick toggles.
- **Network first.**

## Home

```
┌──────────────────────────────────┐
│ [≋ Wi-Fi ›] [ᛒ Bluetooth ›]      │   tiles: icon, name, state line;
│  Home        Buds · 80%          │   click body = toggle,
│ [🎙 Mic   ] [☾ Quiet     ]       │   click › = open page
│  on          off                 │
│                                  │
│ 🔊 ━━━━━━━━━━━━○──────  62%  ›   │   sliders: drag, wheel, arrows;
│ 🎙 ━━━━━━━○───────────  40%  ›   │   icon click = mute
│ ☀  ━━━━━━━━━━○────────  55%      │
│                                  │
│ ⚗ 78% · 3 h 12 m left · Balanced › │
└──────────────────────────────────┘
```

- **Tiles** hold a toggle and, where there is one, a page. Their state line
  is live: the network name, "joining…", the connected device and its
  battery.
- **Sliders** drag, scroll and take arrow keys. They show the live value
  even while it changes elsewhere (media keys).
- **Power row:** charge, time left or to full, and the active profile;
  opens the Power page.
- **Rows that do not apply are hidden:** no brightness without a
  backlight, no battery row on a desktop.

## Pages

Every page has a header with a back arrow, a title and the subject's main
switch, and a list. Rows share one component with explicit states.

- **Idle**, **pending** (spinner, the row is locked), **active** (accent),
  **failed** (the reason under the row, with retry).
- A row's secondary actions (forget, disconnect, details) sit behind `⋯`
  on the row, never as separate links.

### Wi-Fi

- The switch turns Wi-Fi on or off. The scanner runs only while the page
  is open.
- Rows: name, signal bars, lock if secured, and a mark if known. Known
  networks first, then by signal. The list scrolls; no cap.
- Joining a secured, unknown network opens an inline password row. A wrong
  password says so on the row and reopens it.
- `⋯` on a known network: disconnect, forget.
- Wired connections show as one row at the top when present.

### Bluetooth

- The switch powers the adapter. Opening the page starts discovery and
  closing it stops discovery.
- **My devices** (paired) above **Nearby** (discovered). Rows carry a
  device-type icon, battery when reported, and pending states for
  connecting and pairing.
- `⋯`: disconnect, forget.

### Sound

- **Output** and **Input** device lists; choosing one sets the default.
- **Apps:** one slider per playing stream, with its icon, name and a live
  level meter.
- Microphone slider and mute.

### Power

- Charge, state and time remaining, and charge rate.
- Power profile choice: power saver, balanced, performance (the ones the
  system offers).

## Tray

- The hatch keeps its icons; a right click opens a menu drawn in the theme
  from the item's DBus menu: separators, checks, radios, submenus, disabled
  entries, keyboard navigation.
- Left and middle click keep their D-036 meanings.

## Shared kit (runtime components, theme-blind)

In `components/`: `PageStack` (drill-in with slide and back),
`PageHeader`, `ToggleTile`, `Toggle`, `ValueSlider`, `StateRow`
(idle/pending/active/failed, with its `⋯` actions inline under the row),
`PasswordPrompt`, `Spinner`, `SignalBars`. They read
tokens only, so every theme gets them; the plate frame and motion come from
the existing hinged popout host (D-070).

**Keyboard:** Tab and arrows move focus, Enter or Space activates, → or
Enter on a tile opens its page, ← or Backspace goes back, Esc closes.

## Phasing (each ships alone with its own D-number)

1. **Kit and Wi-Fi.** The shared controls; `NetworkState` on
   `Quickshell.Networking`; the control centre home (tiles and volume) and
   the Wi-Fi page. The glance keeps working on the same state names.
2. **Bluetooth.** Discovery, pairing, forget, battery, device icons; the
   Bluetooth page.
3. **Sound.** `AudioState` gains devices, streams, the microphone and
   peaks; the Sound page and the mic tile and slider.
4. **Power, brightness, quiet.** UPower profiles and time remaining, the
   brightness slider and the do-not-disturb tile.
5. **Tray menus.** Themed DBus menus; supersedes D-036.

## Constraints

- One popout at a time, anchored to its glance (L-002). Pages live inside
  the popout, never as new windows.
- Services own state (L-003): pages only call service commands. No row
  keeps its own idea of whether it is connected.
- Theme-blind runtime: labels come from settings, colours from tokens.
- Reduce-motion: pages swap with a fade instead of a slide.
