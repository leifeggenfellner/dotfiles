# Threshold, Gate and Vigil: boot, lock and screensaver brief

Status: **in progress**. Phase 1 (static ring) landed as D-077, phase 2
(Chanis Gate) as D-084, phase 3 (the ascent) as D-085, moved to the login
reveal by D-086 (Plymouth could not animate it smoothly), then dropped by
D-087 (the user did not want it). Shutdown shows no
splash (D-086), replacing the reversed ascent. The rest is a
draft until each phase lands with its own D-number in
`docs/architecture/DECISIONS.md`.

## Why

The surfaces before and around the desktop tell three separate stories. The
boot splash (D-044) is a sigil in fog with an ink ring that fills with boot
progress. The lockscreen (D-037) loops a 17 MB video. There is no
screensaver: after an hour idle the screen goes dark through the idle veil.

This brief makes them one journey through places in the world:

1. **Threshold:** you prove who you are at the passphrase prompt.
2. **Ascent:** you rise through the grey fog to Sefirah Castle.
3. **Gate:** while you are away, Chanis Gate is closed.
4. **Vigil:** while the machine idles, Utopia keeps its rhythm.

Every scene is drawn from layered SVG art that is generated or authored in
the repo and composited cheaply. No video and no fan art.

## 1. Threshold: the passphrase screen

Keep the current screen: the Fool sigil, the glow, the fog and the
"Threshold asks" prompt.

- **Change:** the ink ring is drawn full from the first frame and does not
  animate. Boot progress is no longer shown on the ring; the ascent shows it
  instead.
- **Cost:** this is lighter than today. There are no ring or seep frame
  swaps, and the build renders one ring image instead of 119.
- **Shutdown and reboot:** the ring is static there too until the ascent
  lands; then shutdown and reboot play the ascent in reverse (decided): the
  hall dissolves into fog and the view sinks back to the sigil.

## 2. Ascent to Sefirah Castle: the boot animation

After the passphrase is accepted, you rise through the grey fog to Sefirah
Castle: the ancient palace above the boundless fog, with a vast dome on
towering stone pillars, where the Tarot Club meets.

- **The rise, in Plymouth:** the sigil and prompt fade out. The grey fog
  parts into a slow vortex, with fog banks sliding down past the viewer at
  different speeds (parallax), which reads as rising. Crimson stars hang in
  the fog, the points that tie the castle to people in the world. At the
  vortex's end the palace appears: a pale silhouette of towers and a central
  spire, lit from within.
- **Arrival, the last frame:** the palace hall seen down its length. Two
  rows of stone pillars run toward the dome, with fog pooling on the floor.
  The long bronze table sits in the middle, ten high-backed chairs on each
  side, and the seat at the head is empty. Each chair back glows faintly
  crimson with the outline of a strange constellation. Far behind the
  table, at the end of the hall, there is a faint hint of the door of light.
  It is only a pale glow, never the cocoons.
- **Constraint:** Plymouth's script renderer repaints in software. Moving
  fog already stretches its ticks, so the rise uses a few pre-scaled layers
  that move in steps. The arrival is a still frame, and only the chair
  constellations "breathe" in opacity. Every layer is generated at rebuild
  time, like today's fog and ring.
- **Timing:** after unlock only a few seconds of boot remain, and how many
  varies. The rise is driven by boot progress after unlock, rescaled to
  0–1, so it always reaches the hall before Plymouth quits. On a fast boot
  it arrives quickly, and it never stops halfway.
- **Hand-off to the shell:** greetd logs straight into Hyprland, and the
  session awakening (D-053) opens veiled in fog. With this phase, the
  awakening's first frame is the same hall as the splash's last frame. The
  fog then rises and the hall dissolves into the desktop, as if you take
  the seat at the head of the table. Boot reads as one continuous ascent.
- **Theme data:** `integration.boot` gains an optional `ascent = { landmark;
  hall?; }`. `landmark` is the palace silhouette SVG and `hall` is the
  arrival scene. The fog defaults to generated fog. Themes without `ascent`
  keep the static splash. This needs closed-key validation with must-fail
  cases.
- **Art:** original SVGs in an engraving style, recoloured at build like
  the sigil. The palette is the fog's grey, pale stone, bronze for the
  table, and crimson only for the stars and the constellations. The
  reference images are for mood only; nothing is traced or copied.

## 3. Chanis Gate: the lockscreen

> Superseded by D-091 (2026-11-25): the lock now wears the desktop
> wallpaper with a slow drift; the gate art and opening are removed.

Locking closes Chanis Gate. It is named for Archbishop Chanis, who founded
the modern Nighthawks, and it stands under the central Evernight cathedral
of every major city. Behind it lie the sealed artifacts, the Keepers and
the core seal. The video background is replaced by a drawn scene.

- **At rest:** you look up at the gate from the crypt floor, the way the
  Nighthawks see it.
  - **The gate:** a black iron split gate, heavy, cold and domineering,
    "like a giant guarding in the darkness." Its two leaves carry the seven
    sacred emblems, engraved and filled with dull gilt, with gothic pointed
    panels below them.
  - **The setting:** a pointed stone arch thick with carved tracery, under
    a ribbed vault that disappears into the dark overhead.
  - **Palette:** cold iron and stone in deep verdigris and teal shadow,
    taken from the theme's fog and sunken tokens. Gilt appears only in the
    emblems and the seal, and the warm candle light is the only warmth.
  - **Interface:** the passphrase field sits at the seal where the leaves
    meet. The clock and user name are carved into the lintel. Candle
    sconces stand on each side.
- **Strongest at night:** the gate's power grows after dark. Using the
  local time (and the sky service's sunset where it knows it), the scene
  turns colder and darker in the evening. The emblems take on a faint
  glow, and the candles are guttered low by night. Nothing animates for
  this; the scene simply picks a day or a night set of layers when the lock
  opens.
- **Prayers keep it closed:** the gate siphons a little of the
  worshippers' spirituality to keep its seals. The passphrase is your
  prayer: each typed character lights one of the seven emblems in turn,
  and a wrong passphrase drains them all at once.
- **Motion budget:** candle flames flicker. Moonlight sweeps slowly across
  the leaves, about once a minute. These are the only things that move.
  - Everything stops after about 30 s of no input, then resumes on input.
  - Everything stops as soon as DPMS turns the screen off.
  - Under reduced motion nothing moves.
- **Unlock:** the seal turns, the bars draw back, and the leaves swing
  inward and open (about 600 ms on `Motion`). The session is released as
  they part. If unlock takes too long, the session is released anyway.
- **Wrong passphrase:** the emblems go dark, the seal flares red, and the
  bars rattle once.
- **Cost:** a handful of static images plus two small animated items at low
  frame rates. There is no video decoder per monitor, and no work at all once
  it goes idle. Today the video keeps decoding on all three monitors for the
  whole time the screen is locked.
- **Art:** `lockscreen/lotm/gate/base.png`, generated by the user in
  Midjourney from prompts written for it (the SVG draft is retired).
- **Where it lives:** this is a rework of the LoTM lock variant
  (`lockscreen/lotm/Main.qml`). The video background slot becomes the gate
  scene; the password, user and session logic stay. Cyberpunk and the
  default variant are untouched. `klein_loen.mp4` is no longer used by
  default. It stays in the theme as an opt-in (decided), selectable with
  `RICE_LOCK_VIDEO` as today.

## 4. Vigil: the screensaver (optional)

A new, non-locking screensaver. After a configurable idle time, before the
idle veil and DPMS, a view of Utopia fades in on every screen. Any input
dismisses it at once. It never locks and never holds input.

- **Scene:** Utopia, the marionette town Klein built on an uninhabited
  island off the safe lanes of the Berserk Sea, for his Sequence 1 ritual.
  All of its roughly 5,000 people are marionettes. The view is from the
  hill above the town at dusk turning to night, as a layered engraving:
  - **Foreground:** stone-and-timber rooftops, never more than four storeys,
    in the Desi Bay style, with chimneys and wet slate.
  - **Centre:** the town square and Saint Arianna Cathedral beside it,
    the town's only church (Evernight). Its rose window is lit in
    `accent.primary`, the strongest light in the scene.
  - **Middle distance:** Utopia Station and the railway running out of
    town past the plantations.
  - **Far distance:** the harbour three kilometres off, with two docks,
    the warehouses and a lighthouse, then the open sea.
- **Weather:** Utopia rains often, because it sits in the unsafe waters.
  The scene uses the shell's live sky conditions (D-046): drizzle or a
  rain shower when it rains outside, low cloud when it is overcast, and a
  clear moon otherwise. A distant storm flash out at sea is the most it
  ever gets; there is no lightning over the town.
- **Life, on a schedule:** the town is a little too orderly.
  - **Lamps:** they light street by street in a perfect sequence.
  - **Train:** now and then a steam train crosses the viaduct with a
    plume of steam, always on time.
  - **Lighthouse:** its beam sweeps the sea at an even beat.
  - **Musical tour:** on rest days (weekends), a small procession of
    lanterns moves from the square to the cathedral. Its tune, a faint
    lyre and violin, goes through the sound governor (D-057) and is muted
    by default.
- **The uncanny part:** now and then faint threads catch the moonlight
  above the rooftops and fade again. These are the marionette strings,
  never explained. It should feel calm and slightly wrong, never horror.
- **An entry that moves:** like the Peach Blossom Spring, the town is never
  found the same way twice. Each time the Vigil appears, the view is
  offset a little (parallax origin and the moon's position), so the
  framing never quite repeats.
- **Not shown:** its destruction by Zaratul, Adam and the Lord of Storms.
  The screensaver is the town as Klein made it.
- **Motion:** slow drift of the mist and rain, the lamp sequence, the
  train, the lighthouse beam and the occasional thread glint. Movement
  runs at a low, fixed tick (around 10 fps); the lamp flicker is a cheap
  opacity animation. All of it is under the ambient governor, and it
  stops when DPMS turns off.
- **Art:** about six SVG layers (sky, sea and harbour, railway, cathedral
  and square, foreground roofs, rain), authored in the repo and recoloured
  from tokens at build. Lamps, windows and the beam are small sprites
  placed from coordinates the art exports.
- **Mechanics:** `service.hypridle` gains a `screensaver` listener that fires
  before `idleWarning`. The shell shows the scene through IPC
  (`ambient screensaver on|off`), the same way the idle hint works today. The
  theme opts in with a widget settings block. Without it, nothing changes.

## Phasing (each ships alone with its own D-number)

1. **Static ring.** Plymouth only, and small. Amends D-044.
2. **Chanis Gate lockscreen.** The biggest compute win, so it comes early.
   Art first, then motion.
3. **Ascent to Sefirah Castle.** The Plymouth layers, then the awakening
   hand-off. Extends D-044 and D-053.
4. **Vigil screensaver.** Utopia.

## Constraints

- The runtime stays theme-blind (D-006). Scenes are theme data and assets;
  the runtime gains slots.
- Every new settings key gets closed-key validation with must-fail cases.
- The splash never blocks unlock, and the lock fails open (D-044, D-037
  recovery rules stand).
- All art is original: SVG authored or generated in the repo. No frames or
  stills from adaptations.
- Reduced motion and the ambient governor are honoured everywhere.

## Open decisions

- Screensaver delay. The proposal is 10 minutes, well before the one-hour
  DPMS timeout.
