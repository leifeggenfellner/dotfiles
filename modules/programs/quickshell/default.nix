_: {
  flake.homeModules.programs-quickshell =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = config.rice;

      palettes = import ../../themes/_palettes.nix;
      p = palettes.${osConfig.environment.desktop.theme.scheme};
      style = osConfig.environment.desktop.theme.style;
      accentPrimary = p.${style.accentPrimary};
      accentSecondary = p.${style.accentSecondary};
      accentTertiary = p.${style.accentTertiary};

      sharedAssetsDir = toString cfg.shared.assetsDir;
      lotmAssetsDir = toString cfg.themes.lotm.assetsDir;
      lotmPathwaysDir = toString cfg.themes.lotm.pathwaysDir;
      lotmPathwaysPngDir = toString cfg.themes.lotm.pathwaysPngDir;
      pokemonAssetsDir = toString cfg.themes.pokemon.assetsDir;

      activeThemeAssets =
        if cfg.theme == "lotm" then {
          root = lotmAssetsDir;
          pathwaysDir = lotmPathwaysDir;
          pathwaysPngDir = lotmPathwaysPngDir;
        } else {
          root = pokemonAssetsDir;
        };

      themeJson = pkgs.writeText "theme.json" (builtins.toJSON {
        schemaVersion = 1;
        inherit (cfg) theme;
        assets = {
          shared = sharedAssetsDir;
          active = activeThemeAssets;
          themes = {
            lotm = {
              root = lotmAssetsDir;
              pathwaysDir = lotmPathwaysDir;
              pathwaysPngDir = lotmPathwaysPngDir;
            };
            pokemon = {
              root = pokemonAssetsDir;
            };
          };
        };
        tokens = {
          bg = {
            base = "#${p.base}";
            mantle = "#${p.mantle}";
            elevated = "#${p.surface0}";
            sunken = "#${p.crust}";
            surface1 = "#${p.surface1}";
            surface2 = "#${p.surface2}";
          };
          fg = {
            primary = "#${p.text}";
            muted = "#${p.subtext0}";
            subtle = "#${p.overlay1}";
          };
          accent = {
            primary = "#${accentPrimary}";
            secondary = "#${accentSecondary}";
            tertiary = "#${accentTertiary}";
          };
          state = {
            ok = "#${p.green}";
            warn = "#${p.yellow}";
            danger = "#${p.red}";
          };
          bar = {
            height = 56;
            radius = 12;
            margin = 8;
            spacing = 12;
            opacity = 0.85;
          };
          radius = {
            chip = 8;
            sigil = 10;
            popout = 14;
          };
          space = {
            xs = 4;
            sm = 8;
            md = 12;
            lg = 16;
          };
          dur = {
            fast = 150;
            base = 250;
            slow = 350;
            overlay = 110;
          };
          font = {
            display = "Cinzel";
            mono = style.fontMono;
            sans = style.fontSans;
            sizeBar = style.fontSizeBar;
            sizeSmall = style.fontSizeSmall;
            sizeIcon = style.fontSizeBarIcon;
          };
          motionEnabled = true;
        };
        lotm = {
          pathways = [
            { workspace = 1; id = "fool"; label = "Fool"; icon = "fool.png"; color = "#756a92"; }
            { workspace = 2; id = "door"; label = "Door"; icon = "door.png"; color = "#478eb0"; }
            { workspace = 3; id = "white_tower"; label = "White Tower"; icon = "white_tower.png"; color = "#6678cc"; }
            { workspace = 4; id = "visionary"; label = "Visionary"; icon = "visionary.png"; color = "#8a9aa9"; }
            { workspace = 5; id = "darkness"; label = "Darkness"; icon = "darkness.png"; color = "#5a6d93"; }
            { workspace = 6; id = "sun"; label = "Sun"; icon = "sun.png"; color = "#bc9249"; }
            { workspace = 7; id = "error"; label = "Error"; icon = "error.png"; color = "#8a96a7"; }
          ];
          pathwayCatalog = [
            { id = "abyss"; label = "Abyss"; mainColor = "#d24131"; glowColor = "#a92a1e"; }
            { id = "black_emperor"; label = "Black Emperor"; mainColor = "#0f1115"; glowColor = "#5f728e"; }
            { id = "chained"; label = "Chained"; mainColor = "#ddd9eb"; glowColor = "#8b80ba"; }
            { id = "chaos_mist"; label = "Chaos Mist"; mainColor = "#658593"; glowColor = "#72909c"; }
            { id = "chaos_primogenitor"; label = "Chaos Primogenitor"; mainColor = "#b98467"; glowColor = "#724635"; }
            { id = "darkness"; label = "Darkness"; mainColor = "#c9deef"; glowColor = "#5a6d93"; }
            { id = "death"; label = "Death"; mainColor = "#e9f3da"; glowColor = "#8a9f8b"; }
            { id = "demoness"; label = "Demoness"; mainColor = "#bb4c8a"; glowColor = "#c244a9"; }
            { id = "door"; label = "Door"; mainColor = "#a0e8eb"; glowColor = "#478eb0"; }
            { id = "error"; label = "Error"; mainColor = "#f0f2ef"; glowColor = "#8a96a7"; }
            { id = "eternal_aeon"; label = "Eternal Aeon"; mainColor = "#c5d1e3"; glowColor = "#656f94"; }
            { id = "fool"; label = "Fool"; mainColor = "#c3c2d9"; glowColor = "#756a92"; }
            { id = "hanged_man"; label = "Hanged Man"; mainColor = "#b23137"; glowColor = "#a53238"; }
            { id = "hermit"; label = "Hermit"; mainColor = "#644d9f"; glowColor = "#7d62b4"; }
            { id = "justiciar"; label = "Justiciar"; mainColor = "#efeae7"; glowColor = "#806c54"; }
            { id = "moon"; label = "Moon"; mainColor = "#e3868c"; glowColor = "#c0595d"; }
            { id = "mother"; label = "Mother"; mainColor = "#d1eed2"; glowColor = "#629a81"; }
            { id = "paragon"; label = "Paragon"; mainColor = "#f0c685"; glowColor = "#a96634"; }
            { id = "patriarch"; label = "Patriarch"; mainColor = "#f1d9d7"; glowColor = "#b14d82"; }
            { id = "red_priest"; label = "Red Priest"; mainColor = "#c13e32"; glowColor = "#cc473d"; }
            { id = "second_law"; label = "Second Law"; mainColor = "#e2e8d6"; glowColor = "#7c8b80"; }
            { id = "sublunary_eye"; label = "Sublunary Eye"; mainColor = "#cfb387"; glowColor = "#84633f"; }
            { id = "sun"; label = "Sun"; mainColor = "#f6e68b"; glowColor = "#bc9249"; }
            { id = "twilight_giant"; label = "Twilight Giant"; mainColor = "#e38360"; glowColor = "#a65c3b"; }
            { id = "tyrant"; label = "Tyrant"; mainColor = "#a4edf7"; glowColor = "#466bcb"; }
            { id = "visionary"; label = "Visionary"; mainColor = "#deecf7"; glowColor = "#8a9aa9"; }
            { id = "wheel_of_fortune"; label = "Wheel of Fortune"; mainColor = "#d7e6eb"; glowColor = "#849da2"; }
            { id = "white_tower"; label = "White Tower"; mainColor = "#9ab4eb"; glowColor = "#6678cc"; }
          ];
        };
      });

      # Bundle QML source + generated JSON into one derivation so relative
      # path resolution works at runtime inside the nix store.
      quickshellConfig = pkgs.runCommand "quickshell-config" { } ''
        mkdir -p $out/generated
        cp -r ${./ui}/* $out/
        cp ${themeJson} $out/generated/theme.json
      '';
    in
    {
      config = lib.mkIf cfg.enable {
        home.packages = [
          pkgs.quickshell
        ];
        xdg.configFile."quickshell".source = quickshellConfig;
      };
    };
}
