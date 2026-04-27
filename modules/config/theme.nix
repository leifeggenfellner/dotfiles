_: {
  flake.nixosModules.config-theme =
    { lib, ... }:
    let
      palettes = import ../themes/_palettes.nix;
      schemeNames = builtins.attrNames palettes;
      activeScheme = import ../themes/_active-scheme.nix;
    in
    {
      options.environment.desktop.theme = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable wallpaper configuration";
        };

        scheme = lib.mkOption {
          type = lib.types.enum schemeNames;
          default = activeScheme;
          description = "Active color scheme name. Available: ${builtins.concatStringsSep ", " schemeNames}";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "/home/leif/Pictures/wallpapers/catppuccin/os/nixos_waves.png";
          example = "/home/user/Pictures/wallpaper.png";
          description = "Path to the wallpaper image file";
        };
      };
    };
}
