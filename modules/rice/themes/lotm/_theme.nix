# LOTM theme manifest source (contracts/theme-manifest.md, v1 subset).
# Pure data — no behavior. Underscore prefix keeps import-tree from
# loading it as a flake-parts module; the rice-manifest HM module
# imports it explicitly and serializes it to JSON.
let
  bg = {
    base = "#1b1510"; # dark umber
    mantle = "#151009";
    sunken = "#0e0a06";
    elevated = "#2a211a";
    surface1 = "#3e3121";
    surface2 = "#55432c";
  };
  fg = {
    primary = "#e6d7b8"; # parchment
    muted = "#b5a284";
    subtle = "#857556";
  };
  accent = {
    primary = "#c79a3a"; # antique gold
    secondary = "#9db4c0"; # fog
    tertiary = "#8a3b3b"; # ritual crimson
  };
  state = {
    ok = "#86a361"; # verdigris
    warn = "#d9a441";
    danger = "#b54834"; # rust
    info = "#9db4c0";
  };

  # "#rrggbb" → "rrggbb" for the legacy palette key space.
  strip = c: builtins.substring 1 6 c;

  # The one pathway table (#90). `color` is the pathway's hue (workspace
  # tints, the compass); `accent` is a text-safe variant (≥ 4.5:1 on
  # bg.base) that stands in for accent.primary on the day its tarot card
  # is drawn (D-054). Sigils live at assets/pathways/<id>.svg.
  pathways = {
    fool = { name = "Fool"; color = "#756a92"; accent = "#aaa3cf"; };
    door = { name = "Door"; color = "#478eb0"; accent = "#6fb2d6"; };
    white_tower = { name = "White Tower"; color = "#6678cc"; };
    visionary = { name = "Visionary"; color = "#8a9aa9"; };
    darkness = { name = "Darkness"; color = "#5a6d93"; accent = "#8899ee"; };
    sun = { name = "Sun"; color = "#bc9249"; };
    error = { name = "Error"; color = "#8a96a7"; };
    hermit = { name = "Hermit"; color = "#7d4f72"; accent = "#d48fc0"; };
    wheel_of_fortune = { name = "Wheel of Fortune"; color = "#4f8a6a"; accent = "#7cc49b"; };
    moon = { name = "Moon"; color = accent.tertiary; accent = "#dd7a6e"; };
  };

  # A tarot card belongs to the pathway of its Tarot Club holder: the
  # Magician is Fors (Door), the Hermit and the High Priestess Cattleya's
  # Mystery Pryers, the Star Leonard (Darkness), the Moon Emlyn, the
  # World Klein's Gehrman Sparrow.
  tarot = pathway: card: card // {
    pathway = pathways.${pathway}.name;
    inherit (pathways.${pathway}) accent;
    sigil = "pathways/${pathway}.svg";
  };
  compassPoint = pathway: point: point // { inherit (pathways.${pathway}) name color; };
  workspace = id: pathway: {
    inherit id;
    label = pathways.${pathway}.name;
    icon = "pathways_png/${pathway}.png";
    inherit (pathways.${pathway}) color;
  };
in
{
  meta = {
    name = "lotm";
    displayName = "Lord of the Mysteries";
    version = "0.1.0";
    schemaVersion = 2;
  };

  tokens = {
    colors = { inherit bg fg accent state; };

    typography = {
      families = {
        display = "Cinzel";
        sans = "Inter";
        mono = "JetBrainsMono Nerd Font";
      };
      sizes = {
        small = 10;
        body = 13;
        bar = 14;
        heading = 18;
        icon = 18;
      };
      weights = {
        regular = 400;
        medium = 500;
        bold = 700;
      };
    };

    metrics = {
      radius = {
        small = 8;
        medium = 10;
        large = 14;
      };
      space = {
        xs = 4;
        sm = 8;
        md = 12;
        lg = 16;
      };
      bar = {
        # The Brass Rail (D-063) is flush to the edge, so margin only
        # spaces toasts and popouts below it.
        height = 44;
        margin = 8;
        spacing = 12;
        opacity = 0.88;
      };
      workspaces = {
        slotSize = 30;
        ringExpansion = 4;
        # The sigil sits inside a 30 px bezel (D-065).
        iconSize = 20;
        iconSourceSize = 48;
      };
      dashboard = {
        columnCount = 12;
        compactBreakpoint = 1120;
        sidebarRatio = 0.46;
        sidebarMinWidth = 360;
        sidebarMaxWidth = 560;
        mainMinWidth = 440;
        epigraphMinHeight = 112;
        defaultMinHeight = 180;
      };
    };

    # Window chrome (D-049): antique gilt on the focused border — a pale
    # glint, the gold, and a bronze shadow — and group tabs drawn as
    # tarot cards: the chosen card gilded with dark ink in Cinzel,
    # the rest face-down in umber.
    chrome = {
      border = {
        active = [ "state.warn" "accent.primary" "bg.surface2" "accent.primary" ];
        angle = 45;
      };
      groupbar = {
        active = [ "state.warn" "accent.primary" ];
        inactive = [ "bg.surface1" "bg.elevated" ];
        text = "bg.sunken";
        textInactive = "fg.muted";
        font = "display";
      };
    };

    motion = {
      durations = {
        fast = 160;
        base = 280;
        slow = 400;
        overlay = 120;
        # Reserved for infrequent, deliberate moments (D-022).
        ceremonial = 700;
      };
      # Named curve specs (contracts/motion-contract.md): unhurried
      # entries, sharper exits — a candlelit tempo.
      easings = {
        standard = "OutCubic";
        enter = "OutQuint";
        exit = "InCubic";
        emphasis = "InOutBack";
      };
      intensity = "calm";
      # Window motion (D-047): windows emerge from the fog — a slow pop
      # in on the enter curve while they fade up — and burn away, a
      # quick shrink on the exit curve with a short fade. Workspaces
      # drift through each other vertically; layers fade. The gilded
      # border's glint turns once around a window as it takes focus.
      compositor = {
        windowsIn = "popin 85%";
        windowsOut = "popin 92%";
        workspaces = "slidefadevert 15%";
        layers = "fade";
        borderSweep = "once";
      };
      # Opt into the ambient atmosphere tier (D-021); the runtime
      # governor still pauses it on battery/fullscreen/reduce-motion.
      ambient = true;
      enabled = true;
    };

    # Ambient atmosphere (D-021): gray fog hugging the desktop floor,
    # ember motes drifting up, a candlelit vignette. Tints are color
    # token refs (L-005) — fog wears the fog-blue accent, embers the
    # antique gold.
    effects.layers = [
      { type = "fog"; tint = "accent.secondary"; opacity = 0.18; speed = 1.15; band = "bottom"; }
      { type = "particles"; tint = "accent.primary"; opacity = 0.42; count = 12; speed = 1.1; }
      { type = "vignette"; tint = "bg.sunken"; opacity = 0.30; }
    ];

    # Sky presets (D-046). Near a full moon the Crimson Moon rises: fog,
    # embers and vignette turn ritual crimson. Rain draws fine fog-blue
    # streaks; real fog outside thickens the fog inside.
    effects.presets = [
      {
        when = "fullMoon";
        window = 1.5;
        tints = { fog = "accent.tertiary"; particles = "state.danger"; vignette = "accent.tertiary"; };
        strength = { fog = 1.3; vignette = 1.5; };
      }
      {
        when = "rain";
        layers = [{ type = "rain"; tint = "accent.secondary"; opacity = 0.22; count = 90; speed = 1.0; }];
      }
      { when = "fog"; strength.fog = 1.8; }
    ];
  };

  assets = {
    # root is set by mkThemeManifest (path context must survive into
    # the JSON, or GC can sweep the source snapshot — see
    # _manifest-lib.nix).
    # Official LOTM lockscreen. The launcher still allows CLI/env
    # overrides, and the rice-native lockscreen remains available as
    # `rice-lock-screen --variant default` for recovery/debugging.
    lockscreenVariant = "lotm";
    # Icon-name overrides: values with a "/" are files relative to
    # assets.root; anything else is a font glyph.
    icons = {
      calendar = "icons/sigil_calendar.svg";
      lock = "icons/sigil_lock.svg";
      settings = "icons/sigil_settings.svg";
      logout = "icons/sigil_logout.svg";
      messenger = "icons/sigil_messenger.svg";
      monitor = "instruments/lens.svg";
      moon = "icons/sigil_moon.svg";
      moon-new = "icons/sigil_moon.svg";
      moon-waxing-crescent = "icons/sigil_moon.svg";
      moon-first-quarter = "icons/sigil_moon.svg";
      moon-waxing-gibbous = "icons/sigil_moon.svg";
      moon-full = "icons/sigil_moon.svg";
      moon-waning-gibbous = "icons/sigil_moon.svg";
      moon-last-quarter = "icons/sigil_moon.svg";
      moon-waning-crescent = "icons/sigil_moon.svg";
      power = "icons/sigil_power.svg";
      reboot = "icons/sigil_reboot.svg";
      weather = "icons/sigil_weather.svg";
      # The rail's instruments (D-064): engraved brass line art.
      wifi = "instruments/antenna-3.svg";
      wifi-0 = "instruments/antenna-0.svg";
      wifi-1 = "instruments/antenna-1.svg";
      wifi-2 = "instruments/antenna-2.svg";
      wifi-3 = "instruments/antenna-3.svg";
      wifi-off = "instruments/antenna-off.svg";
      ethernet = "instruments/conduit.svg";
      volume = "instruments/horn.svg";
      volume-muted = "instruments/horn-stoppered.svg";
      bluetooth = "instruments/fork.svg";
      battery = "instruments/vial.svg";
      battery-charging = "instruments/vial-charging.svg";
      battery-ink = "instruments/vial-ink.svg";
      battery-ink-low = "instruments/vial-ink-low.svg";
      music = "instruments/disc.svg";
    };
    sounds = {
      notification = "sounds/sealed-letter.wav";
      notification-critical = "sounds/red-seal.wav";
      messenger = "sounds/messenger.wav";
      # Shell cues (D-057); recipes in assets/sounds/src.
      launcher-open = "sounds/launcher-open.wav";
      power-open = "sounds/power-open.wav";
      lock = "sounds/lock.wav";
      unlock = "sounds/unlock.wav";
      workspace = "sounds/workspace.wav";
      satchel-seal = "sounds/satchel-seal.wav";
      tarot-flip = "sounds/tarot-flip.wav";
      # Sound bed loops (D-058).
      bed-rain = "sounds/bed-rain.ogg";
      bed-crackle = "sounds/bed-crackle.ogg";
      bed-bells = "sounds/bed-bells.ogg";
      bed-fog = "sounds/bed-fog.ogg";
      hour-bell = "sounds/sealed-letter.wav";
      lore = "sounds/red-seal.wav";
    };
    # Build-time SVG→PNG rendering (D-011); output appears in the
    # manifest as assets.raster.<name>.
    rasterize = [
      { name = "pathways"; src = "pathways"; size = 64; }
    ];
  };

  # Per-widget configuration (contracts/widget-contract.md tier 2).
  # Workspace identity is the pathway catalog — pure theme data; the
  # runtime's WorkspacesGlance knows nothing about pathways.
  widgets =
    {
      launcher.settings = {
        placeholder = "Speak the honorific name...";
        epigraphs = [
          "The fog listens. The desktop answers."
          "A name, once spoken, becomes a door."
          "Every summoning begins as a precise request."
        ];
        incantations = {
          enabled = true;
          entries = [
            {
              phrase = "the fool above the gray fog";
              event = "incantation";
              text = "A ripple crosses the gray fog.";
              sound = "lore";
              surge = true;
            }
            {
              phrase = "the world needs a door";
              event = "incantation";
              text = "Somewhere, a brass key turns without a hand.";
              sound = "lore";
              surge = false;
            }
          ];
        };
        maxResults = 16;
      };

      # The Brass Rail (D-063): a brass instrument rail flush to the top
      # edge. The start cog with the Fool in its hub opens the launcher;
      # the power seal closes the far end.
      bar.settings = {
        style = "rail";
        frame = {
          body = { src = "bar/rail.svg"; slice = [ 24 0 24 0 ]; };
          plaque = { src = "bar/plaque.svg"; slice = [ 8 8 8 8 ]; };
        };
        caps = {
          start = { action = "launcher"; plate = "bar/cog.svg"; emblem = "pathways_png/fool.png"; turn = 30; };
          end = { action = "power"; plate = "bar/seal.svg"; emblem = "power"; };
        };
        glow = { rest = "accent.primary"; hover = "state.warn"; };
      };

      clock.settings.layout = "inline";

      # Instruments (D-064). The vial's ink runs from 0.21 (full) to
      # 0.79 (empty) of the icon's height; it turns rust at 15% and pulses at 5%.
      system.settings = {
        bluetooth = true;
        showTray = false;
        batteryGauge = { full = 0.21; empty = 0.79; };
        lowBattery = 0.15;
        criticalBattery = 0.05;
      };
      media.settings = { hideIdle = true; disc = true; };
      "monitor-profile".settings.showLabel = false;
      tray = {
        enabled = true;
        settings = { maxInline = 3; tone = "sepia"; title = "The Hatch"; };
      };

      # Polkit prompt (D-062): a privileged act needs a higher seal. The
      # real request, identity and action id are always shown beneath.
      polkit.settings = {
        title = "A Seal of Authority";
        epigraph = "This rite reaches beyond your own Sequence. Affix your seal to let it pass.";
        submitLabel = "Affix the seal";
        cancelLabel = "Withdraw";
        identityLabel = "sealed by";
        retryText = "The seal did not take. Try again.";
        maskCharacter = "◆";
        icon = "lock";
        sound = "satchel-seal";
      };

      worldEvents.settings = {
        hourBell = {
          enabled = true;
          event = "hourBell";
          text = "The hour bell tolls beyond the fog.";
          sound = "hour-bell";
          surge = false;
        };
        dailyFogSurge = {
          enabled = true;
          event = "dailyFogSurge";
          text = "The gray fog rises for the new day.";
          sound = "lore";
          surge = true;
          hour = 6;
          minute = 0;
        };
      };

      # Session awakening (D-053): the first shell start of a login opens
      # veiled in gray fog; the Fool's words surface beside the real user
      # and time, then the fog lifts off the desktop.
      awakening.settings = {
        title = "Above the Gray Fog";
        subtitle = "The Fool awakens";
        hold = 2200;
        lift = 3200;
        sound = "lore";
      };

      epigraph.settings = {
        title = "Observatory";
        lines = [
          "Above the gray fog, every gauge becomes an omen."
          "A scholar records the machine before interpreting the miracle."
          "Quiet instruments reveal what loud rituals conceal."
        ];
        # Sky conditions (D-046) swap in their own sets.
        skyLines = {
          fullMoon = [
            "The Crimson Moon is high; madness walks closer to the surface."
            "Under the red moon, keep your rituals short and your doors locked."
            "Moonlight the colour of old blood — a night for careful Beyonders."
          ];
          rain = [
            "Rain over Tingen; the Nighthawks walk their rounds regardless."
            "Wet cobblestones remember every footstep."
          ];
          fog = [
            "Real fog at the window, gray fog above it."
            "On nights like this, the boundary thins."
          ];
        };
      };

      meters.settings = {
        title = "Beyonder Vitals";
        labels = {
          cpu = { title = "Spirituality expenditure"; plain = "CPU"; };
          memory = { title = "Corruption pressure"; plain = "RAM"; };
          temperature = { title = "Loss of control"; plain = "temperature"; };
          disk = { title = "The Archive"; plain = "disk /"; };
        };
        colors = {
          cpu = accent.secondary;
          memory = accent.tertiary;
          temperature = state.warn;
          disk = accent.primary;
        };
        corruptionColor = "#5e3038";
        calmText = "stable";
        dangerText = "corruption edge";
        danger = {
          cpu = 0.85;
          memory = 0.90;
          temperature = 85;
          temperatureMax = 100;
          disk = 0.90;
        };
      };

      correspondence.settings = {
        title = "Correspondence";
        clearLabel = "burn";
        quietLabel = "sealed";
        audibleLabel = "open";
        emptyLabel = "No letters under the door.";
        dndEmptyLabel = "The mailbox is sealed.";
        # Personas (D-056): these apps' letters arrive by messenger. The
        # label sits beside the real app name; summary and actions stay.
        personas = [
          {
            apps = [ "discord" "vesktop" "slack" "signal" "telegram" "org.telegram.desktop" "element" "whatsapp" ];
            label = "borne by Reinette Tinekerr";
            icon = "messenger";
            sound = "messenger";
            variant = "letter";
          }
        ];
      };

      satchel.settings = {
        title = "Artifact Satchel";
        placeholder = "Search collected fragments...";
        emptyText = "No artifacts have been collected.";
        sealedLabel = "sealed";
        maxResults = 24;
      };

      power.settings = {
        delegate = "radial";
        centerLabel = "Ritual";
        labels = {
          lock = "Seal";
          logout = "Depart";
          reboot = "Recast";
          poweroff = "Extinguish";
        };
      };

      "session-lock".settings = {
        label = "Sanctify";
        hint = "Seal the sanctuary against the gray fog.";
      };

      weather.settings = {
        title = "Sky Omens";
        unavailableText = "The weather is veiled beyond the fog.";
      };

      calendar.settings = {
        title = "Almanac";
        moonLabel = "Lunar divination";
        # The real phase and illumination stay under the flavour label.
        skyLabels.fullMoon = { text = "Crimson Moon"; tint = "accent.tertiary"; };
        secret = {
          enabled = true;
          event = "calendarSecret";
          text = "Klein's calendar has one more page than it should.";
          sound = "lore";
          surge = true;
        };
      };

      tarotDraw.settings = {
        title = "Tarot Draw";
        prompt = "Draw today's omen";
        emptyLabel = "The deck waits under the fog.";
        cards = [
          (tarot "fool" {
            id = "fool";
            name = "The Fool";
            sequence = "0";
            phrase = "A door opens above the gray fog.";
            face = "fool.png";
            back = "fool.png";
          })
          (tarot "door" {
            id = "magician";
            name = "The Magician";
            sequence = "I";
            phrase = "A precise hand turns chance into ritual.";
            face = "magician.png";
            back = "magician.png";
          })
          (tarot "hermit" {
            id = "high-priestess";
            name = "The High Priestess";
            sequence = "II";
            phrase = "Silence keeps the safer half of knowledge.";
            face = "priestess.png";
            back = "priestess.png";
          })
          (tarot "hermit" {
            id = "hermit";
            name = "The Hermit";
            sequence = "IX";
            phrase = "A lamp is enough when the path is honest.";
            face = "hermit.png";
            back = "hermit.png";
          })
          (tarot "wheel_of_fortune" {
            id = "wheel-of-fortune";
            name = "Wheel of Fortune";
            sequence = "X";
            phrase = "The machine turns; the omen is timing.";
            face = "wheel.png";
            back = "wheel.png";
          })
          (tarot "darkness" {
            id = "star";
            name = "The Star";
            sequence = "XVII";
            phrase = "The night keeps its vigil; hope returns to the water.";
            face = "star.png";
            back = "star.png";
          })
          (tarot "moon" {
            id = "moon";
            name = "The Moon";
            sequence = "XVIII";
            phrase = "Not every shadow belongs to a monster.";
            face = "moon.png";
            back = "moon.png";
          })
          (tarot "fool" {
            id = "world";
            name = "The World";
            sequence = "XXI";
            phrase = "A circle closes without becoming a cage.";
            face = "world.png";
            back = "world.png";
          })
        ];
      };

      # Window inspector (D-043): Spirit Vision. Labels sit beside the
      # real CPU/RSS/process/workspace values, never instead of them.
      inspector.settings = {
        title = "Spirit Vision";
        subtitle = "auras of the living";
        labels = {
          cpu = "Spirituality";
          memory = "Corruption";
          processes = "Entangled souls";
          workspace = "Realm";
        };
      };

      # Workspace moods (D-045): the focus workspace (Super+0) is the
      # Sefirah Castle above the gray fog — the Fool's throne behind the
      # windows, fog rising through the whole screen, letters held until
      # you descend.
      mood.settings.workspaces.focus = {
        title = "Above the Gray Fog";
        backdrop = "wallpapers/klein_chair.jpg";
        dnd = true;
        sound = "lore";
        # The gray fog itself: a pale wash that greys the castle out, and
        # a dense fog sea rolling under it.
        veil = { tint = "accent.secondary"; wash = 0.3; density = 0.85; };
        effects = [
          { type = "fog"; tint = "accent.secondary"; opacity = 0.35; speed = 0.6; band = "full"; }
          { type = "fog"; tint = "fg.primary"; opacity = 0.3; speed = 0.4; band = "bottom"; }
          { type = "particles"; tint = "accent.primary"; opacity = 0.25; count = 4; speed = 0.5; }
          { type = "vignette"; tint = "bg.sunken"; opacity = 0.18; }
        ];
      };

      # Sound bed (D-058), opt-in: a gramophone left running in a Tingen
      # study, bells across the city, Backlund rain when it really rains.
      # Above the gray fog the city falls away to the fog's own wind.
      soundscape.settings.layers = [
        { sound = "bed-crackle"; volume = 0.6; }
        { sound = "bed-bells"; volume = 0.3; }
        { sound = "bed-rain"; volume = 0.8; when = "rain"; }
        { sound = "bed-fog"; volume = 0.9; mood = "focus"; }
      ];

      # Zen's new tab as a Backlund broadsheet (D-060): the real date,
      # weather and moon from the shell, the day's omen and an epigraph.
      newtab.settings = {
        title = "The Backlund Daily";
        tagline = "Printed above the gray fog · All the news the Church permits";
        epigraphs = "widgets.epigraph.settings.lines";
        daily = {
          record = "extras.tarotDraw.daily";
          catalog = "widgets.tarotDraw.settings.cards";
          format = "{sequence} · {name} · {pathway} pathway — {phrase}";
          pendingLabel = "The cards are still face-down under the gray fog.";
        };
        labels = {
          weather = "Weather over Backlund";
          moon = "The Crimson Moon";
          omen = "Today's omen";
          links = "Notices";
          offline = "No dispatch from the shell";
        };
      };

      # Daily accent (D-054): the day's tarot card lends its pathway's
      # accent to the shell, the window borders and the terminal card.
      dailyAccent.settings = {
        record = "extras.tarotDraw.daily";
        catalog = "widgets.tarotDraw.settings.cards";
      };

      # Terminal consumers (rice-terminal, D-042): the fish greeting shows the
      # same daily card the Observatory drew.
      terminal.settings = {
        greeting.daily = {
          record = "extras.tarotDraw.daily";
          autoDraw = true;
          catalog = "widgets.tarotDraw.settings.cards";
          format = "Today's omen · {sequence} · {name} · {pathway} pathway — {phrase}";
          pendingLabel = "The cards are still face-down under the gray fog.";
        };
        commandNotFound.format = "Unknown incantation: {command}";
        # Starship as a Beyonder's notebook (D-050): the pathway of the
        # workspace beside its number, the git counts as Sequence notes,
        # and a failed ritual beside the real exit code or signal.
        prompt = {
          workspace = {
            catalog = "widgets.workspaces.settings.items";
            glyph = "☉";
            format = "{glyph} {label} {id}";
          };
          git.label = "Sequence";
          failure.label = "failed ritual";
        };
        # Neovim (D-052): the scheme from these tokens, and a start screen
        # that opens on the Observatory's epigraphs above recent files.
        neovim = {
          colorscheme = true;
          start = {
            title = "Above the Gray Fog";
            epigraphs = "widgets.epigraph.settings.lines";
            recentLabel = "Recent manuscripts";
          };
        };
        # fastfetch as a Beyonder Characteristic card (D-051): the Fool
        # sigil in gilt, each row's diegetic label beside its real key.
        fastfetch = {
          title = "Beyonder Characteristic";
          logo = "pathways/fool.svg";
          labels = {
            user = "Vessel";
            distro = "Pathway";
            kernel = "Sequence";
            uptime = "Awakened";
            shell = "Grimoire";
            mem = "Spirituality";
            pkgs = "Artefacts";
          };
        };
      };

      ritualLedger.settings = {
        title = "Daily Ritual";
        entries = [
          { id = "observe"; label = "Observe"; }
          { id = "record"; label = "Record"; }
          { id = "anchor"; label = "Anchor"; }
          { id = "seal"; label = "Seal"; }
        ];
      };

      pathwayCompass.settings = {
        title = "Pathway Compass";
        activeIndex = 0;
        pathways = [
          (compassPoint "fool" { sequence = "9"; state = "acting"; })
          (compassPoint "door" { sequence = "8"; state = "listening"; })
          (compassPoint "visionary" { sequence = "7"; state = "recording"; })
        ];
      };

      workspaces.settings = {
        items = [
          (workspace 1 "fool")
          (workspace 2 "door")
          (workspace 3 "white_tower")
          (workspace 4 "visionary")
          (workspace 5 "darkness")
          (workspace 6 "sun")
          (workspace 7 "error")
        ];
        # Sigil bezels (D-065): aged brass, polished when active, a gauge
        # needle below, and a ritual-crimson rim for urgent windows.
        bezel = {
          plate = "bar/bezel.svg";
          activePlate = "bar/bezel-active.svg";
          needle = "bar/needle.svg";
          urgent = "accent.tertiary";
        };
        # Workspace carousel (D-067): tarot plates on a brass drum.
        carousel = {
          card = { src = "bar/card.svg"; slice = [ 24 24 24 24 ]; };
          nameplate = { src = "bar/nameplate.svg"; slice = [ 14 8 14 8 ]; };
          copy = { none = "Unclaimed"; one = "1 window"; many = "{n} windows"; };
          # Window captures (D-068), washed to sepia in the brass gold.
          capture = { tint = "accent.primary"; strength = 0.4; };
        };
      };
    };

  plugins = [
    {
      id = "tarotDraw";
      source = "widgets/TarotDraw";
      entry = "TarotDraw.qml";
      region = "dashboard";
      priority = 40;
      services = [ "prefs" ];
      unloadWhenClosed = true;
      layout = { column = "main"; minHeight = 320; };
    }
    {
      id = "ritualLedger";
      source = "widgets/RitualLedger";
      entry = "RitualLedger.qml";
      region = "dashboard";
      priority = 50;
      services = [ "prefs" ];
      unloadWhenClosed = true;
      layout = { column = "sidebar"; minHeight = 148; };
    }
    {
      id = "pathwayCompass";
      source = "widgets/PathwayCompass";
      entry = "PathwayCompass.qml";
      region = "dashboard";
      priority = 60;
      services = [ ];
      unloadWhenClosed = true;
      layout = { column = "main"; minHeight = 180; };
    }
  ];

  # Rebuild-time surfaces (D-012), for the configured theme.
  integration = {
    # Boot splash (D-044): the Fool sigil rises through the gray fog. The
    # label sits above systemd's real passphrase prompt, never in place of it.
    boot = {
      sigil = ./assets/pathways/fool.svg;
      promptLabel = "The Threshold asks";
      font = ./lockscreen/lotm/font/Cinzel-Bold.ttf;
    };

    # Terminal tools themed from these tokens (D-051): btop's meters run
    # fog → gold → rust, bat reads like an annotated grimoire, yazi wears
    # gilt tabs, cava burns like a candle. VS Code, Spotify and Discord
    # (D-059) wear the bar's umber and gold.
    tools = [ "btop" "bat" "yazi" "cava" "vscode" "spotify" "discord" "zen" ];

    # Cursor (D-048): a quill to write with and a gloved hand to point,
    # gilded on umber ink. Built into hyprcursor + XCursor at rebuild;
    # rice-switch applies it live. Hotspots are fractions of the SVG.
    cursor =
      let
        shape = file: hotspot: { svg = ./assets/cursor + "/${file}.svg"; inherit hotspot; };
        centre = file: shape file [ 0.5 0.5 ];
      in
      {
        name = "lotm-quill";
        size = 24;
        shapes = {
          default = shape "default" [ 0.0625 0.0625 ];
          progress = shape "progress" [ 0.0625 0.0625 ];
          pointer = shape "pointer" [ 0.375 0.0625 ];
          text = centre "text";
          wait = centre "wait";
          ns-resize = centre "ns-resize";
          ew-resize = centre "ew-resize";
          nwse-resize = centre "nwse-resize";
          nesw-resize = centre "nesw-resize";
          move = centre "move";
          crosshair = centre "crosshair";
          not-allowed = centre "not-allowed";
        };
      };
  };

  # Legacy palette bridge (D-012): fills the repo's classic palette
  # key space so GTK/Qt/hyprlock/Hyprland recolor from this theme.
  # Structural keys derive from tokens; chromatic extras are
  # LOTM-flavored. Accent trick: the style defaults reference
  # mauve/blue/sapphire — mapped here to gold/fog/crimson.
  palette.legacy = {
    base = strip bg.base;
    mantle = strip bg.mantle;
    crust = strip bg.sunken;
    surface0 = strip bg.elevated;
    surface1 = strip bg.surface1;
    surface2 = strip bg.surface2;
    text = strip fg.primary;
    subtext1 = "cbbb99";
    subtext0 = strip fg.muted;
    overlay2 = "9a8a6b";
    overlay1 = strip fg.subtle;
    overlay0 = "6b5e45";
    red = strip state.danger;
    green = strip state.ok;
    yellow = strip state.warn;
    blue = strip accent.secondary;
    mauve = strip accent.primary;
    sapphire = strip accent.tertiary;
    sky = strip state.info;
    maroon = "9a3f30";
    peach = "cf8f4a";
    teal = "7d9b82";
    lavender = "a99ac0";
    pink = "b98a92";
    flamingo = "c9a58e";
    rosewater = "e0cbb4";
  };
}
