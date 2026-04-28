_: {
  flake.homeModules.programs-btop =
    { lib, osConfig, ... }:
    let
      inherit (osConfig.environment.desktop.theme) scheme;
      btopTheme = {
        "catppuccin-mocha" = "catppuccin_mocha";
        "catppuccin-macchiato" = "catppuccin_macchiato";
        "catppuccin-frappe" = "catppuccin_frappe";
        "catppuccin-latte" = "catppuccin_latte";
        "nord" = "nord";
        "tokyo-night" = "tokyo-night";
        "rose-pine" = "Default";
        "gruvbox-dark" = "gruvbox_dark";
        "dracula" = "dracula";
      }.${scheme} or "Default";
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.btop = {
          enable = true;
          settings = {
            color_theme = btopTheme;
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
