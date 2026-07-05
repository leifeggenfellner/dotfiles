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
      };
      enabled = true;
    };
  };

  assets = {
    # root is set by mkThemeManifest (path context must survive into
    # the JSON, or GC can sweep the source snapshot — see
    # _manifest-lib.nix).
    # Icon-name overrides: values with a "/" are files relative to
    # assets.root; anything else is a font glyph.
    icons = {
      settings = "icons/sigil_settings.svg";
      monitor = "icons/sigil_eye.svg";
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
