_: {
  flake.nixosModules.config-theme =
    { lib, ... }:
    {
      options.environment.desktop.theme = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable wallpaper configuration";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "/home/leif/Sources/walls-catppuccin-mocha/flower-branch.png";
          example = "/home/user/Pictures/wallpaper.png";
          description = "Path to the wallpaper image file";
        };
      };
    };
}
