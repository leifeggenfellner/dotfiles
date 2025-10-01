{ osConfig
, inputs
, config
, pkgs
, lib
, ...
}:
let
  wallpaper = "${config.home.homeDirectory}/Sources/walls-catppuccin-mocha/flower-branch.png";
in
{

  options.program.hyprlock = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable hyprlock";
    };

    defaultMonitor = lib.mkOption {
      type = lib.types.str;
      default = "desc:HP Inc. HP E45c G5 CNC50212K0";
      description = "Set the default monitor.";
    };
  };

  config = lib.mkIf (config.program.hyprlock.enable && osConfig.environment.desktop.windowManager == "hyprland") {
    programs.hyprlock = {
      enable = true;
      package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

      settings = {
        general = {
          disable_loading_bar = true;
          immediate_render = true;
          hide_cursor = false;
          no_fade_in = true;
        };

        # Correct animation: single string, comma-separated
        animation = "inputFieldDots, 1, 2, linear, fadeIn, 0";

        background = [
          {
            monitor = "";   # all monitors
            path = "${wallpaper}";
          }
        ];

        input_field = [
          {
            monitor = config.program.hyprlock.defaultMonitor;   # only default monitor
            size = "300, 50";
            valign = "center";
            position = "50%, 50%";

            outline_thickness = 1;

            font_color = "rgb(b6c4ff)";
            outer_color = "rgba(180, 180, 180, 0.5)";
            inner_color = "rgba(200, 200, 200, 0.1)";
            check_color = "rgba(247, 193, 19, 0.5)";
            fail_color = "rgba(255, 106, 134, 0.5)";

            fade_on_empty = false;
            placeholder_text = "Enter Password";

            dots_spacing = 0.2;
            dots_center = true;
            dots_fade_time = 100;

            shadow_color = "rgba(0, 0, 0, 0.1)";
            shadow_size = 7;
            shadow_passes = 2;
          }
        ];

        label = [
          {
            monitor = "";
            text = "$TIME";
            font_size = 150;
            color = "rgb(b6c4ff)";

            position = "0%, 30%";

            valign = "center";
            halign = "center";

            shadow_color = "rgba(0, 0, 0, 0.1)";
            shadow_size = 20;
            shadow_passes = 2;
            shadow_boost = 0.3;
          }
          {
            monitor = "";
            text = "cmd[update:3600000] date +'%a %b %d'";
            font_size = 20;
            color = "rgb(b6c4ff)";

            position = "0%, 40%";

            valign = "center";
            halign = "center";

            shadow_color = "rgba(0, 0, 0, 0.1)";
            shadow_size = 20;
            shadow_passes = 2;
            shadow_boost = 0.3;
          }
        ];
      };
    };
  };
}

