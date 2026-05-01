# LOTM theme manifest source (contracts/theme-manifest.md, v1 subset).
# Pure data — no behavior. Underscore prefix keeps import-tree from
# loading it as a flake-parts module; the rice-manifest HM module
# imports it explicitly and serializes it to JSON.
{
  meta = {
    name = "lotm";
    displayName = "Lord of the Mysteries";
    version = "0.1.0";
    schemaVersion = 2;
  };

  tokens = {
    colors = {
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
    };

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
    root = toString ./assets;
    # Icon-name overrides: values with a "/" are files relative to
    # assets.root; anything else is a font glyph.
    icons = {
      settings = "icons/sigil_settings.svg";
      monitor = "icons/sigil_eye.svg";
    };
  };
}
