_: {
  flake = {

    nixosModules = {
      rice =
        { lib, config, ... }:
        let
          cfg = config.rice;
          themesDir = ./rice/themes;
          themeNames = lib.attrNames (lib.filterAttrs
            (name: type: type == "directory" && builtins.pathExists (themesDir + "/${name}/_theme.nix"))
            (builtins.readDir themesDir));
          themeType = lib.types.enum themeNames;
        in
        {
          options.rice = {
            enable = lib.mkEnableOption "multi-theme rice system";

            theme = lib.mkOption {
              type = themeType;
              default = "lotm";
              description = "Active rice theme profile.";
            };

            specialisations = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Build NixOS/Home Manager specialisations for packaged rice themes.";
              };

              themes = lib.mkOption {
                type = lib.types.listOf themeType;
                default = themeNames;
                description = "Rice themes that should receive generated NixOS specialisations.";
              };

              prefix = lib.mkOption {
                type = lib.types.str;
                default = "rice-";
                description = "Prefix used for generated NixOS specialisation names.";
              };
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
