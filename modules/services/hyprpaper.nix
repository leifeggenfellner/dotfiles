_: {
  flake.homeModules.services-hyprpaper =
    { lib, pkgs, osConfig, ... }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home.packages = [
          pkgs.awww
          pkgs.waypaper
        ];

        # waypaper config — uses awww backend, recursive wallpaper dir
        # Mutable so waypaper can save the user's wallpaper selection and
        # --restore picks it up on next boot. Home Manager seeds the file
        # only when it doesn't already exist (force = false).
        xdg.configFile."waypaper/config.ini" = {
          force = false;
          text = ''
            [Settings]
            language = en
            folder = ~/Pictures/wallpapers
            wallpaper = ${wallpaper}
            backend = awww
            monitors = All
            fill = fill
            sort = name
            color = #000000
            subfolders = True
            show_hidden = False
            show_gifs_only = False
            post_command =
            swww_transition_type = fade
            swww_transition_step = 90
            swww_transition_angle = 0
            swww_transition_duration = 2
            swww_transition_fps = 60
            use_awww = True
          '';
        };
      };
    };
}
