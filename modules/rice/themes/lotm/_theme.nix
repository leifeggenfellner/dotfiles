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
        height = 56;
        margin = 8;
        spacing = 12;
        opacity = 0.88;
      };
      workspaces = {
        slotSize = 30;
        ringExpansion = 4;
        iconSize = 24;
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
      monitor = "icons/sigil_eye.svg";
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
    };
    sounds = {
      notification = "sounds/sealed-letter.wav";
      notification-critical = "sounds/red-seal.wav";
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
        columns = 4;
        maxResults = 16;
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
          {
            id = "fool";
            name = "The Fool";
            sequence = "0";
            phrase = "A door opens above the gray fog.";
            face = "fool.png";
            back = "fool.png";
          }
          {
            id = "magician";
            name = "The Magician";
            sequence = "I";
            phrase = "A precise hand turns chance into ritual.";
            face = "magician.png";
            back = "magician.png";
          }
          {
            id = "high-priestess";
            name = "The High Priestess";
            sequence = "II";
            phrase = "Silence keeps the safer half of knowledge.";
            face = "priestess.png";
            back = "priestess.png";
          }
          {
            id = "hermit";
            name = "The Hermit";
            sequence = "IX";
            phrase = "A lamp is enough when the path is honest.";
            face = "hermit.png";
            back = "hermit.png";
          }
          {
            id = "wheel-of-fortune";
            name = "Wheel of Fortune";
            sequence = "X";
            phrase = "The machine turns; the omen is timing.";
            face = "wheel.png";
            back = "wheel.png";
          }
          {
            id = "moon";
            name = "The Moon";
            sequence = "XVIII";
            phrase = "Not every shadow belongs to a monster.";
            face = "moon.png";
            back = "moon.png";
          }
          {
            id = "world";
            name = "The World";
            sequence = "XXI";
            phrase = "A circle closes without becoming a cage.";
            face = "world.png";
            back = "world.png";
          }
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

      # Terminal consumers (rice-terminal, D-042): the fish greeting shows the
      # same daily card the Observatory drew.
      terminal.settings = {
        greeting.daily = {
          record = "extras.tarotDraw.daily";
          autoDraw = true;
          catalog = "widgets.tarotDraw.settings.cards";
          format = "Today's omen · {sequence} · {name} — {phrase}";
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
          { name = "Fool"; sequence = "9"; state = "acting"; color = "#756a92"; }
          { name = "Door"; sequence = "8"; state = "listening"; color = "#478eb0"; }
          { name = "Visionary"; sequence = "7"; state = "recording"; color = "#8a9aa9"; }
        ];
      };

      workspaces.settings.items = [
        { id = 1; label = "Fool"; icon = "pathways_png/fool.png"; color = "#756a92"; }
        { id = 2; label = "Door"; icon = "pathways_png/door.png"; color = "#478eb0"; }
        { id = 3; label = "White Tower"; icon = "pathways_png/white_tower.png"; color = "#6678cc"; }
        { id = 4; label = "Visionary"; icon = "pathways_png/visionary.png"; color = "#8a9aa9"; }
        { id = 5; label = "Darkness"; icon = "pathways_png/darkness.png"; color = "#5a6d93"; }
        { id = 6; label = "Sun"; icon = "pathways_png/sun.png"; color = "#bc9249"; }
        { id = 7; label = "Error"; icon = "pathways_png/error.png"; color = "#8a96a7"; }
      ];
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
    # gilt tabs, cava burns like a candle.
    tools = [ "btop" "bat" "yazi" "cava" ];

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
