# Cyberpunk theme manifest source (contracts/theme-manifest.md).
# Pure data — no behavior. Underscore prefix keeps import-tree from
# loading it as a flake-parts module; the rice-manifest HM module
# imports it explicitly and serializes it to JSON.
#
# Phase 9 validation theme (ROADMAP): deliberately data-ONLY — no
# authored artwork, identity carried entirely by tokens, fonts, and
# Nerd Font glyphs — to prove a theme needs nothing but a manifest.
let
  bg = {
    base = "#0b0f1a"; # night city black-blue
    mantle = "#080b13";
    sunken = "#05070d";
    elevated = "#141b2b";
    surface1 = "#1e2940";
    surface2 = "#2a3956";
  };
  fg = {
    primary = "#d6e5ff"; # ice
    muted = "#93a7c8";
    subtle = "#5f7194";
  };
  accent = {
    primary = "#00e5ff"; # neon cyan
    secondary = "#ff2ec4"; # hot magenta
    tertiary = "#f5d90a"; # warning-tape yellow
  };
  state = {
    ok = "#3ddc97";
    warn = "#ffb020";
    danger = "#ff4d6d";
    info = "#4dc9ff";
  };

  # "#rrggbb" → "rrggbb" for the legacy palette key space.
  strip = c: builtins.substring 1 6 c;
in
{
  meta = {
    name = "cyberpunk";
    displayName = "Cyberpunk";
    version = "0.1.0";
    schemaVersion = 2;
  };

  tokens = {
    colors = { inherit bg fg accent state; };

    typography = {
      families = {
        display = "Orbitron";
        sans = "Chakra Petch";
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
      # Hard edges: near-zero radii are the theme's silhouette.
      radius = {
        small = 2;
        medium = 4;
        large = 8;
      };
      space = {
        xs = 4;
        sm = 8;
        md = 12;
        lg = 16;
      };
      bar = {
        height = 48;
        margin = 6;
        spacing = 10;
        opacity = 0.92;
      };
    };

    motion = {
      # Snappier than LOTM across the board — the theme's tempo.
      durations = {
        fast = 110;
        base = 190;
        slow = 300;
        overlay = 80;
      };
      enabled = true;
    };
  };

  assets = {
    # root is set by mkThemeManifest. Glyph-only overrides (D-016):
    # no value contains "/", so this theme ships zero icon files.
    # The rice-native lockscreen fits cyberpunk's palette, so we opt
    # out explicitly rather than relying on the "default" default.
    lockscreenVariant = "default";
    icons = {
      settings = "";
      monitor = "󰍹";
      power = "⏻";
    };
  };

  # Per-widget configuration (contracts/widget-contract.md tier 2).
  # Workspace identity as pure glyph data — exercises the glyph arm
  # of the identity contract (LOTM exercises the image arm).
  widgets = {
    workspaces.settings.items = [
      { id = 1; label = "Deck"; icon = "󰆍"; color = "#00e5ff"; }
      { id = 2; label = "Grid"; icon = "󰖟"; color = "#4dc9ff"; }
      { id = 3; label = "Forge"; icon = "󰅩"; color = "#7aa2ff"; }
      { id = 4; label = "Link"; icon = "󰭹"; color = "#9d5cff"; }
      { id = 5; label = "Feed"; icon = "󰝚"; color = "#c44dff"; }
      { id = 6; label = "Core"; icon = "󰒋"; color = "#ff2ec4"; }
      { id = 7; label = "Void"; icon = "󰇘"; color = "#ff6b9d"; }
    ];
  };

  # Legacy palette bridge (D-012): fills the repo's classic palette
  # key space so GTK/Qt/hyprlock/Hyprland recolor from this theme.
  # Accent trick (as in LOTM): the style defaults reference
  # mauve/blue/sapphire — mapped here to cyan/magenta/yellow.
  palette.legacy = {
    base = strip bg.base;
    mantle = strip bg.mantle;
    crust = strip bg.sunken;
    surface0 = strip bg.elevated;
    surface1 = strip bg.surface1;
    surface2 = strip bg.surface2;
    text = strip fg.primary;
    subtext1 = "b4c6e4";
    subtext0 = strip fg.muted;
    overlay2 = "7d8fb0";
    overlay1 = strip fg.subtle;
    overlay0 = "4a5a78";
    red = strip state.danger;
    green = strip state.ok;
    yellow = strip state.warn;
    blue = strip accent.secondary;
    mauve = strip accent.primary;
    sapphire = strip accent.tertiary;
    sky = strip state.info;
    maroon = "d13a57";
    peach = "ff9e64";
    teal = "2fd6c4";
    lavender = "9d5cff";
    pink = "ff6b9d";
    flamingo = "ff8fab";
    rosewater = "ffc9d4";
  };
}
