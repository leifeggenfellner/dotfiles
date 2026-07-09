_: {
  flake = {

    nixosModules = {
      rice =
        { lib, config, ... }:
        let
          cfg = config.rice;
          themeLib = import ./rice/nix/_themes-lib.nix { inherit lib; };
          bundledThemeNames = lib.attrNames themeLib.bundledThemePackages;
          packageType = lib.types.path;
          themeConfigType = lib.types.submodule ({ name, config, ... }: {
            freeformType = lib.types.attrsOf lib.types.anything;
            options = {
              package = lib.mkOption {
                type = lib.types.nullOr packageType;
                default = null;
                description = "External rice theme package root containing _theme.nix.";
              };

              assetsDir = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Compatibility asset directory for bundled/theme-specific modules.";
              };

              pathwaysDir = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = if name == "lotm" && config.assetsDir != null then config.assetsDir + "/pathways" else null;
                description = "Compatibility LOTM pathway SVG icon directory.";
              };

              pathwaysPngDir = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = if name == "lotm" && config.assetsDir != null then config.assetsDir + "/pathways_png" else null;
                description = "Compatibility LOTM pathway colored PNG icon directory.";
              };
            };
          });
        in
        {
          options.rice = {
            enable = lib.mkEnableOption "multi-theme rice system";

            theme = lib.mkOption {
              type = lib.types.str;
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
                type = lib.types.listOf lib.types.str;
                default = [ ];
                description = "Rice themes that should receive generated NixOS specialisations. Empty means all packaged themes.";
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

            themes = lib.mkOption {
              type = lib.types.attrsOf themeConfigType;
              default = { };
              description = "Rice theme package configuration keyed by theme name.";
            };
          };

          config = lib.mkMerge [
            {
              rice.themes.lotm.assetsDir = lib.mkDefault ./rice/themes/lotm/assets;
            }
            (lib.mkIf cfg.enable {
              assertions =
                let
                  packages = themeLib.themePackages cfg;
                  names = lib.attrNames packages;
                  specialisationThemes = if cfg.specialisations.themes == [ ] then names else cfg.specialisations.themes;
                in
                [
                  {
                    assertion = lib.hasAttr cfg.theme packages;
                    message = "rice.theme '${cfg.theme}' is not packaged. Available themes: ${lib.concatStringsSep ", " names}";
                  }
                  {
                    assertion = lib.all (name: lib.hasAttr name packages) specialisationThemes;
                    message = "rice.specialisations.themes contains an unpackaged theme. Available themes: ${lib.concatStringsSep ", " names}";
                  }
                  {
                    assertion = lib.all (name: builtins.pathExists (packages.${name} + "/_theme.nix")) names;
                    message = "Each rice theme package must contain _theme.nix at its package root.";
                  }
                  {
                    assertion = lib.all (name: lib.elem name names) bundledThemeNames;
                    message = "Internal error: bundled rice theme discovery failed.";
                  }
                ];
            })
          ];
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
