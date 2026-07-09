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
      { type = "fog"; tint = "accent.secondary"; opacity = 0.10; speed = 1.0; band = "bottom"; }
      { type = "particles"; tint = "accent.primary"; opacity = 0.30; count = 9; speed = 1.0; }
      { type = "vignette"; tint = "bg.sunken"; opacity = 0.25; }
    ];
  };

  assets = {
    # root is set by mkThemeManifest (path context must survive into
    # the JSON, or GC can sweep the source snapshot — see
    # _manifest-lib.nix).
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
  widgets = {
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

    media.settings = {
      title = "Gramophone";
      idleTitle = "Silent gramophone";
      maxTitleWidth = 150;
    };

    dock.settings = {
      enabled = true;
      monitorPolicy = "focused";
      maxItems = 6;
      apps = [
        { match = "Code"; label = "Scriptorium"; }
        { match = "foot"; label = "Terminal"; }
        { match = "Zen Browser"; label = "Browser"; }
        { match = "Slack"; label = "Correspondence"; }
        { match = "Discord"; label = "Gathering"; }
        { match = "Spotify"; label = "Gramophone"; }
      ];
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

    weather.settings = {
      title = "Sky Omens";
      unavailableText = "The weather is veiled beyond the fog.";
    };

    calendar.settings = {
      title = "Almanac";
      moonLabel = "Lunar divination";
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
      redrawLabel = "redraw";
      emptyLabel = "The deck waits under the fog.";
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
    }
    {
      id = "ritualLedger";
      source = "widgets/RitualLedger";
      entry = "RitualLedger.qml";
      region = "dashboard";
      priority = 50;
      services = [ "prefs" ];
    }
    {
      id = "pathwayCompass";
      source = "widgets/PathwayCompass";
      entry = "PathwayCompass.qml";
      region = "dashboard";
      priority = 60;
      services = [ ];
    }
  ];

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
