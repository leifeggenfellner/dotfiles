_: {
  flake = {

    nixosModules = {
      rice =
        { lib, config, ... }:
        let
          cfg = config.rice;
          themeType = lib.types.enum [
            "lotm"
            "pokemon"
          ];
        in
        {
          options.rice = {
            enable = lib.mkEnableOption "multi-theme rice system";

            theme = lib.mkOption {
              type = themeType;
              default = "lotm";
              description = "Active rice theme profile.";
            };

            shared = {
              assetsDir = lib.mkOption {
                type = lib.types.path;
                default = ./rice/shared/assets;
                description = "Shared rice assets directory.";
              };
            };

            themes = {
              lotm = {
                assetsDir = lib.mkOption {
                  type = lib.types.path;
                  default = ./rice/themes/lotm/assets;
                  example = "./modules/rice/themes/lotm/assets";
                  description = "LOTM theme asset directory.";
                };

                pathwaysDir = lib.mkOption {
                  type = lib.types.path;
                  default = cfg.themes.lotm.assetsDir + "/pathways";
                  example = "./modules/rice/themes/lotm/assets/pathways";
                  description = "LOTM pathway SVG icon directory.";
                };

                pathwaysPngDir = lib.mkOption {
                  type = lib.types.path;
                  default = cfg.themes.lotm.assetsDir + "/pathways_png";
                  description = "LOTM pathway colored PNG icon directory.";
                };
              };

              pokemon = {
                assetsDir = lib.mkOption {
                  type = lib.types.path;
                  default = ./rice/themes/pokemon/assets;
                  example = "./modules/rice/themes/pokemon/assets";
                  description = "Pokemon theme asset directory.";
                };
              };
            };
          };
        };

      rice-theme-lotm =
        { config, lib, ... }:
        {
          config = lib.mkIf (config.rice.enable && config.rice.theme == "lotm") {
            # LOTM-specific settings will be added incrementally.
          };
        };

      rice-theme-pokemon =
        { config, lib, ... }:
        {
          config = lib.mkIf (config.rice.enable && config.rice.theme == "pokemon") {
            # Pokemon-specific settings will be added when this theme is implemented.
          };
        };
    };

    homeModules = {
      rice =
        { lib, osConfig, ... }:
        {
          options.rice = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "Home-manager view of the active NixOS rice configuration.";
          };

          config.rice = osConfig.rice;
        };
    };
  };
}
