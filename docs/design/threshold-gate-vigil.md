# Threshold, Gate and Vigil: boot, lock and screensaver brief

Status: **draft**, for review. Nothing here is decided until a phase lands
with its own D-number in `docs/architecture/DECISIONS.md`.

## Why

The surfaces before and around the desktop tell three separate stories. The
boot splash (D-044) is a sigil in fog with an ink ring that fills with boot
progress. The lockscreen (D-037) loops a 17 MB video. There is no
screensaver: after an hour idle the screen goes dark through the idle veil.

This brief makes them one journey through places in the world:

1. **Threshold:** you prove who you are at the passphrase prompt.
2. **Ascent:** you rise through the grey fog to Sefirah Castle.
3. **Gate:** while you are away, Chanis Gate is closed.
4. **Vigil:** while the machine idles, a city keeps watch.

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
- **Shutdown and reboot:** the ring is static there too. (Open question: should
  shutdown play the ascent in reverse?)

## 2. Ascent to Sefirah Castle: the boot animation

After the passphrase is accepted, the camera rises through the grey fog until
Sefirah Castle comes into view above it, an ancient stone castle floating on
the fog.

- **Plymouth part:** the sigil and prompt fade out. Three or four fog banks
  slide down past the viewer at different speeds (parallax), which reads as
  rising. The castle silhouette comes down into frame from the top and
  settles in the upper third with a faint glow behind it.
- **Constraint:** Plymouth's script renderer repaints in software. Moving
  fog already stretches its ticks, so the ascent uses few, pre-scaled
  layers that move in steps. Layers are generated at rebuild time, like
  today's fog and ring.
- **Timing:** after unlock only a few seconds of boot remain, and how many
  varies. The ascent is driven by boot progress after unlock, rescaled to
  0–1, so it always arrives at the castle before Plymouth quits. On a fast
  boot it arrives quickly; it never stops halfway.
- **Hand-off to the shell:** greetd logs straight into Hyprland, and the
  session awakening (D-053) opens veiled in fog. With this phase, the
  awakening's first frame is the same castle-in-fog view as the splash's last
  frame. The fog then lifts onto the desktop, so boot reads as one continuous
  ascent.
- **Theme data:** `integration.boot` gains an optional `ascent = { landmark;
  layers?; }`. `landmark` is the castle SVG. The fog layers default to
  generated fog. Themes without `ascent` keep the static splash. This needs
  closed-key validation with must-fail cases.
- **Art:** a castle silhouette in a lithograph or engraving style: towers,
  arched windows, and the long hall where the Tarot Club meets, lit from
  within in `accent.primary`. It is drawn as a single SVG in the repo and
  recoloured at build, like the sigil.

## 3. Chanis Gate: the lockscreen

Locking closes Chanis Gate, the sealed gate under Saint Selena Cathedral that
the Nighthawks guard. The video background is replaced by a drawn scene.

- **At rest:** the screen shows the gate's two heavy black iron leaves, set
  in a stone arch. They carry the Evernight emblem (the crimson moon and
  stars) in engraved gilt. Candle sconces stand on each side. The passphrase
  field sits at the seal where the leaves meet. The clock and user name are
  carved into the lintel.
- **Motion budget:** candle flames flicker. Moonlight sweeps slowly across
  the leaves, about once a minute. These are the only things that move.
  - Everything stops after about 30 s of no input, then resumes on input.
  - Everything stops as soon as DPMS turns the screen off.
  - Under reduced motion nothing moves.
- **Unlock:** the seal turns, the bars draw back, and the leaves swing
  inward and open (about 600 ms on `Motion`). The session is released as
  they part. If unlock takes too long, the session is released anyway.
- **Wrong passphrase:** the seal flares red and the bars rattle once.
- **Cost:** a handful of static images plus two small animated items at low
  frame rates. There is no video decoder per monitor, and no work at all once
  it goes idle. Today the video keeps decoding on all three monitors for the
  whole time the screen is locked.
- **Where it lives:** this is a rework of the LoTM lock variant
  (`lockscreen/lotm/Main.qml`). The video background slot becomes the gate
  scene; the password, user and session logic stay. Cyberpunk and the
  default variant are untouched. `klein_loen.mp4` is no longer used by
  default, so its 17 MB can leave the theme. (Open question: keep it as an
  opt-in?)

## 4. Vigil: the screensaver (optional)

A new, non-locking screensaver. After a configurable idle time, before the
idle veil and DPMS, a city scene fades in on every screen. Any input
dismisses it at once. It never locks and never holds input.

- **Scene:** a Victorian city at dusk or night, seen from a rooftop: layered
  rooftops, chimneys, a clock tower and gas lamps, with fog moving through
  the streets and the moon overhead.
  - **Open:** which city is "Klein's paradise city"? I could not place the
    name. Backlund, Tingen, or something from later in the story?
- **Motion:** slow parallax drift of the fog and the farthest skyline. A few
  windows light up and go dark over minutes, and the gas lamps flicker. It
  runs at a low, fixed tick (around 10 fps for movement; the flicker is a
  cheap opacity animation) under the ambient governor. It stops when DPMS
  turns off.
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
4. **Vigil screensaver.** After the city is settled.

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

- Shutdown: a static full ring, or the ascent in reverse (a descent into the
  fog)?
- Which city the Vigil shows.
- Whether `klein_loen.mp4` stays as an opt-in lock background or is removed.
- Screensaver delay. The proposal is 10 minutes, well before the one-hour
  DPMS timeout.
