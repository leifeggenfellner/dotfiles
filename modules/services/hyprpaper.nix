{ inputs, ... }: {
  flake.homeModules.services-hyprpaper =
    { lib, pkgs, osConfig, ... }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
    in
    {
      services.hyprpaper = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        enable = true;
        package = inputs.hyprpaper.packages.${pkgs.stdenv.hostPlatform.system}.default;

        settings = {
          preload = [ "${wallpaper}" ];
          wallpaper = [ ", ${wallpaper}" ];
        };
      };
    };
}
