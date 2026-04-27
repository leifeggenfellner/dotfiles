_: {
  flake.homeModules.programs-btop =
    { lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.btop = {
          enable = true;
          settings = {
            color_theme = "catppuccin_mocha";
            theme_background = false;
            vim_keys = true;
            rounded_corners = true;
            shown_boxes = "cpu mem net proc";
            update_ms = 1000;
            proc_tree = true;
            proc_gradient = true;
            clock_format = "%H:%M";
          };
        };
      };
    };
}
