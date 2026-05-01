_: {
  flake.homeModules.programs-quickshell =
    { lib, pkgs, config, ... }:
    let
      cfg = config.rice;

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
