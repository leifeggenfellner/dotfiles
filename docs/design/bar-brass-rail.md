# The Brass Rail: taskbar redesign brief

Status: **proposed** (design brief, no code yet). Tracked in issue #92. When a phase lands, its decision goes into
`docs/architecture/DECISIONS.md` as a new D-number and this brief links to it.

## Why

The current bar (`modules/bar/TopBar.qml`) is a floating, rounded, translucent
pill holding a row of Material-style glyphs. It has LoTM colours, but its form
is the generic 2020s Linux rice. The pathway workspace icons are the only part
that feels like it belongs to the world. The right side reads like a phone
status bar: "No track title" and "laptop only" are shown as plain text, and
the icons are flat.

## Direction (confirmed)

**Brass machine, arcane power.** The bar is a piece of Victorian occult
engineering, like a rail bolted across the top of an instrument in a Backlund
workshop.

- **Brass and iron form the structure:** rivets, bezels, end caps and
  engraved plates.
- **The occult forms the power:** gauges read spirituality, bezels hold
  pathway sigils, and the light inside is candle and ink glow rather than
  LEDs.

The steampunk look comes from the materials and the arcane from the content.
Neither should become a costume. No cartoon gears, no photo textures, no
sci-fi.

- **Form:** a full-width instrument rail flush to the top edge. It is not a
  floating pill.
- **Workspaces:** pathway sigils stay. Each sigil sits in a brass bezel.
- **Workspace preview:** a carousel of tarot-card plates turning on a drum.
  Each plate shows the pathway sigil in front of a dimmed live capture of that
  workspace's windows.

## Anatomy

```
╔═◉══════════════════════════════════════════════════════════════════◉═╗
║ ⚙ ┃ (☉)(◇)(◈)(✦)(☾)(☼)(✶) ┃        ⌛  23:13  ⌛        ┃ ▣▣ ┃ ≋ ♪ ⚗ ┃ ⏻ ║
╚═╧═╤══════════════════════╤═╧═════════╤═══════╤═════════╧═╤══╧══════╤═╧═╝
  start      workspace plaque          chronometer          tray  instruments  power
```

### 1. The rail (frame)

- **Placement:** full width, flush to the top edge, with no outer margin or
  corner radius. The bottom edge is a thin brass rule with small tick marks
  under each plaque, like a ruler on an instrument.
- **Body:** dark umber, nearly opaque (≥ 0.95). The current 0.88 translucency
  is part of the "modern glass" read.
  - A subtle vertical gradient, `bg.elevated` at the top to `bg.mantle` at the
    bottom, makes it a solid object.
  - A 1 px parchment highlight runs along the top edge of the brass rule.
- **Plaques:** recessed panels with an inner shadow and a 1 px brass bevel,
  one per group. Groups are separated by the depth of the plaques, not by
  gaps.
- **Height:** about 44 px, down from 56. The rail looks heavier, so it can
  afford to be thinner. The final value is set in Phase 1 against real
  screenshots.
- **Built from rebuild-time SVG:** the frame pieces (end caps, rule, plaque
  bevel) are theme SVGs rasterised at rebuild, the same pattern as the cursor
  (D-048) and Plymouth (D-044) assets. The runtime draws them with
  `BorderImage`, so the frame scales to any width without blur.

### 2. End caps: start and power

- **Left cap, the start emblem:** a brass cog with the Fool sigil engraved in
  its hub, held by two rivets. A click opens the launcher.
  - The cog turns one notch, about 30°, on the emphasis curve when the
    launcher opens, and turns back when it closes. It never spins
    continuously.
  - Hover warms the hub glow from candle to gold.
- **Right cap, power:** the mirror image. A brass seal plate with
  `sigil_power.svg` opens the existing power popout. Moving power out of the
  right-hand cluster balances the rail.

### 3. Workspace plaque: the sigil bezels

- **Bezel:** each of the 7 pathway sigils sits in a round brass bezel.
- **States:**

  | State | Look |
  |---|---|
  | Empty | Sigil engraved: monochrome, `fg.subtle`, at about 45% opacity |
  | Occupied | Sigil inked in its pathway colour at about 80%, with one small brass rivet under the bezel |
  | Active | Bezel polished to bright gold, sigil at full colour with a soft glow in its pathway colour, and a gauge needle under the plaque pointing at it |
  | Urgent | The bezel rim pulses ritual crimson, twice per notice, then holds a crimson rim with no animation |

- **Needle motion:** the needle sweeps between bezels on the emphasis curve,
  the same "instrument settles" motion as the cog.
- **Interactions:**
  - A click switches workspace.
  - Scrolling over the plaque turns the carousel without switching (see
    below).
  - Middle-click moves the focused window to that workspace.
- **Size:** bezel diameter about 30 px, sigil about 22 px. Hit targets stay at
  30 px or more.

### 4. The workspace carousel

This is the signature moment. It is a preview drum of tarot-card plates, shown
under the workspace plaque.

- **Triggers:**
  - Switching workspace by keybind shows it, turns it to the new card, and
    dismisses it after about 900 ms idle.
  - Hovering the plaque for 350 ms shows it, and it follows the hovered
    bezel.
  - Scrolling turns it.
  - Clicking a card switches to that workspace.
  - Esc or moving the pointer away dismisses it.
- **Layout:** the centre card is large, about 320×200. The two neighbours on
  each side are rotated about 35° on a shared drum axis, scaled down, and
  dimmed. Cards further out are hidden.
- **Card face:**
  - Behind: a dimmed live capture of that workspace (a sepia/umber tint at
    about 40%).
  - In front: the pathway sigil, large, with its glow.
  - Across the bottom: a brass nameplate with the pathway name in Cinzel
    small caps and "3 windows" in Inter.
  - An empty workspace shows the pathway's ink fog instead of a capture.
- **Captures:**
  - Use `ScreencopyView` on each `HyprlandToplevel.wayland`, with
    `live: false` and one `captureFrame()` per open.
  - Never stream; the hardware is an Intel iGPU on battery.
  - Captures are composited into a workspace-shaped miniature using the
    toplevels' `lastIpcObject` geometry.
  - **Feasibility spike (Phase 4a):** confirm that Hyprland exports frames for
    windows on *inactive* workspaces. If it doesn't, cache the last capture
    taken while each workspace was visible, and fall back to app icons.
- **Fallback chain:** live capture, then cached capture, then app icons, then
  sigil only. Any one missing still leaves a complete card.
- **Reduced motion and the governor:** no drum rotation. Cards cross-fade in
  place and the auto-dismiss still applies. With captures disabled, the
  carousel uses the icon fallback.
- **Multi-monitor:** it shows on the screen whose bar was used, or the
  focused screen for keybind switches. Only that monitor's workspaces turn.

### 5. Chronometer (centre)

- **Medallion:** a brass-ringed plaque with the time in Cinzel (tabular
  figures) and the date below in small caps, e.g. "THU · 19 NOV".
- **Moon phase:** a small engraved moon-phase pip on the left of the
  medallion. It ties into the Crimson Moon sky preset (D-046).
- **Unchanged:** the click behaviour (opens the Observatory).

### 6. Instruments (right cluster)

Every glyph is replaced with an engraved instrument icon from one new SVG
family: line art, brass on umber, 1.5 px strokes at 18 px.

| Today | Becomes | Reads |
|---|---|---|
| Wi-Fi fan | Aether antenna: a mast with 0–3 arcs | Signal strength |
| Speaker | Speaking-tube horn | Muted shows a stopper in the horn |
| Battery + "93%" | Spirituality vial: a glass vial whose ink level is the charge | Charging adds rising bubbles; the percentage stays beside it in mono |
| ♪ "No track title" | Phonograph plaque: a small disc that turns only while playing, with the title marquee | **Hidden entirely when nothing is playing** |
| 👁 "laptop only" | Lens icon only | Profile name moves to the tooltip and the popout |
| Bluetooth | Resonance fork | Shown only when on |

- **Low states:** at 15% or less, the vial and other low states turn rust.
  Nothing in the rail flashes except urgent workspaces and a critical battery
  (≤ 5%).

### 7. The tray: a hinged compartment

- **Today:** app tray icons are hidden inside the system popout.
- **Closed:** they move into a small brass hatch on the rail, a compartment
  showing up to 3 app icons. The icons are toned to sepia so third-party
  colours don't break the rail.
- **Hover:** shows the icons in full colour.
- **Click:** opens the hatch, a plate that drops down hinged with every tray
  item.
- **Menus:** stay app-native (D-036).
- **No items:** the hatch disappears.

### 8. Popouts become hinged plates

- **Shape:** the existing popouts (system, media, power, monitor) drop from
  the rail as brass-framed plates hinged at the top, instead of floating
  rounded cards. The motion is a short swing-down: the enter curve, with a
  2° overshoot settling flat.
- **Content:** unchanged. This is a frame and motion change only.

## Motion budget

- **At rest the rail is static:** no constantly running animation. The only
  exception is the phonograph disc while music plays, and it pauses under the
  governor.
- **Ceremonial moments**, using `Motion.ceremonial`:
  - the cog notch;
  - the needle sweep;
  - the carousel turn;
  - the hatch swing.
- **Reduced motion:** every ceremonial moment becomes a cross-fade.

## Theme-blind split (D-006)

The runtime gains **slots**; LoTM fills them. Without theme data, the bar
keeps today's rounded-rect look.

| Runtime (theme-blind) | LoTM theme provides |
|---|---|
| `metrics.bar.style = "floating" \| "rail"` and frame `BorderImage` slots (caps, rule, plaque) | Brass cap, rule and plaque SVGs |
| End-cap actions: `left = launcher`, `right = power` | Cog + Fool hub, seal + power sigil |
| Workspace bezel states (empty, occupied, active, urgent) plus needle | Bezel SVG, needle SVG, state colours as token refs |
| `modules/workspaceCarousel` + its settings | Card frame, nameplate, copy ("{n} windows"), tint |
| Icon slots for system glyphs (`widgets.system.settings.icons`) | The instrument icon family |
| Tray compartment with `maxInline` and `tone` | Hatch art, `tone = "sepia"` |
| Popout frame slot | Hinged-plate frame |

Every new `settings` key goes into `_manifest-lib.nix`'s closed-key validation
with must-fail cases, as the polkit prompt did (D-062).

## Phases

Each phase ships on its own and gets its own D-number.

1. **Rail frame and end caps.** The `rail` bar style, frame slots, LoTM frame
   SVGs, and the start cog that opens the launcher, with power moved to the
   right cap.
2. **Instruments and tray compartment.** The icon family, the vial, antenna
   and horn, the phonograph plaque hidden when idle, the lens, and the hatch.
3. **Sigil bezels and needle.** The workspace states, the needle sweep, and
   middle-click to move a window.
4. **Workspace carousel.**
   - 4a: capture spike.
   - 4b: drum and cards with the icon fallback.
   - 4c: live and cached captures.
5. **Hinged-plate popouts and polish.** Frames, swing motion, and a
   reduced-motion pass.

## Anti-goals

- Photo or bitmap brass textures, lens flares, cartoon gears, constantly
  spinning anything.
- Losing information to flavour. Battery percentage, time and network state
  stay readable at a glance.
- Blur-heavy glass, rounded pills, or Material icons left over from the old
  look.
- Per-theme branches in runtime code.
- Restyling app-native tray menus.

## Open decisions

- Rail height (44 px proposed) and whether the rail appears on all three
  monitors or only the focused one. Proposal: all three, carousel on one.
- Whether a keybind workspace switch should *always* show the carousel or
  only after a hold. Proposal: always, with a short 900 ms dismiss. Revisit
  after living with it.
- Whether the icon family is hand-drawn SVG in-repo or adapted from an
  existing engraved set. Licensing must allow redistribution in the repo.
