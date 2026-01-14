{ osConfig
, pkgs
, lib
, ...
}:
{
  config = lib.mkMerge [
    (lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
      home.persistence."/persist/" = {
        directories = [
          ".config/spotify"
          ".cache/spotify"
        ];
      };

      # Install regular Spotify
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
}
