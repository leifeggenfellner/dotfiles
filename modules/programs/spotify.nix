_: {
  flake.homeModules.programs-spotify =
    { osConfig, pkgs, lib, ... }:
    {
      config = lib.mkMerge [
        (lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
          home.persistence."/persist/" = {
            directories = [
              ".config/spotify"
              ".cache/spotify"
            ];
          };

          home.packages = with pkgs; [
            spotify
          ];
        })
        (lib.mkIf (osConfig.environment.desktop.windowManager == "gnome") {
          home.packages = [
            pkgs.spotify
          ];
        })
      ];
    };
}
