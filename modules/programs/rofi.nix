{ osConfig
, config
, pkgs
, lib
, ...
}:
let
  commonSettings = {
    font = "RobotoMono Nerd Font";
    fontsize = "12";
  };
in
{
  programs.rofi = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
    enable = true;
    package = pkgs.rofi-wayland;

    extraConfig = {
      modi = "drun,run,window";
      show-icons = true;
      terminal = "foot";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-drun = "   Apps ";
      display-run = "   Run ";
      display-window = " 﩯  Window";
      display-Network = " 󰤨  Network";
      sidebar-mode = true;
      steal-focus = true;
    };

    theme = let
      inherit (config.colorScheme) palette;
    in {
      "*" = {
        bg-col = "#${palette.base00}";
        bg-col-light = "#${palette.base01}";
        border-col = "#${palette.base0D}";
        selected-col = "#${palette.base0D}";
        blue = "#${palette.base0D}";
        fg-col = "#${palette.base05}";
        fg-col2 = "#${palette.base08}";
        grey = "#${palette.base03}";

        width = 600;
        font = "${commonSettings.font} ${commonSettings.fontsize}";
      };

      "element-text, element-icon , mode-switcher" = {
        background-color = "inherit";
        text-color = "inherit";
      };

      "window" = {
        height = 360;
        border = 3;
        border-color = "@border-col";
        background-color = "@bg-col";
        border-radius = 20;
      };

      "mainbox" = {
        background-color = "@bg-col";
      };

      "inputbar" = {
        children = map (p: p + ";") ["prompt" "entry"];
        background-color = "@bg-col";
        border-radius = 15;
        padding = 2;
      };

      "prompt" = {
        background-color = "@blue";
        padding = 6;
        text-color = "@bg-col";
        border-radius = 12;
        margin = 20;
      };

      "textbox-prompt-colon" = {
        expand = false;
        str = ":";
      };

      "entry" = {
        padding = 6;
        margin = 20;
        text-color = "@fg-col";
        background-color = "@bg-col";
      };

      "listview" = {
        border = 0;
        padding = 6;
        margin = 10;
        columns = 1;
        lines = 5;
        background-color = "@bg-col";
      };

      "element" = {
        padding = 5;
        background-color = "@bg-col";
        text-color = "@fg-col";
        border-radius = 12;
      };

      "element-icon" = {
        size = 25;
      };

      "element selected" = {
        background-color = "@selected-col";
        text-color = "@bg-col";
      };

      "mode-switcher" = {
        spacing = 0;
      };

      "button" = {
        padding = 10;
        background-color = "@bg-col-light";
        text-color = "@grey";
        vertical-align = 0.5;
        horizontal-align = 0.5;
      };

      "button selected" = {
        background-color = "@bg-col";
        text-color = "@blue";
      };

      "message" = {
        background-color = "@bg-col-light";
        margin = 2;
        padding = 2;
        border-radius = 5;
      };

      "textbox" = {
        padding = 6;
        margin = 20;
        text-color = "@blue";
        background-color = "@bg-col-light";
      };
    };
  };
}
