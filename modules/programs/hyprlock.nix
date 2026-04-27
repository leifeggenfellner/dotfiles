{ inputs, ... }: {
  flake.homeModules.programs-hyprlock =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
      c = config.theme.colors;
      fmt = import ../themes/_fmt.nix lib;
      cfg = config.program.hyprlock;

      statusColors = {
        check_color = fmt.rgba c.green "1.0";
        fail_color = fmt.rgba c.red "1.0";
        bothlock_color = fmt.rgba c.yellow "1.0";
        capslock_color = fmt.rgba c.peach "1.0";
        numlock_color = fmt.rgba c.sky "1.0";
      };
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
          default = "";
          description = "Monitor to show lock UI on. Set per-host in _home.nix. The lock-screen script overrides this at runtime.";
        };
      };

      config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
        programs.hyprlock = {
          enable = true;
          package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;

          settings = {
            general = {
              immediate_render = true;
              hide_cursor = false;
            };

            background = [
              {
                monitor = "";
                path = "${wallpaper}";
                blur_passes = 2;
                contrast = 0.9;
                brightness = 0.8;
                vibrancy = 0.2;
                vibrancy_darkness = 0.0;
              }
            ];

            "input-field" = [
              ({
                monitor = cfg.defaultMonitor;
                size = "280, 50";
                outline_thickness = 2;
                dots_size = 0.16;
                dots_spacing = 0.3;
                dots_center = true;
                outer_color = fmt.rgba c.mauve "0.8";
                inner_color = fmt.rgba c.surface0 "0.8";
                font_color = fmt.rgba c.text "1.0";
                fade_on_empty = false;
                placeholder_text = "hunter2";
                hide_input = false;
                position = "0, 80";
                halign = "center";
                valign = "bottom";
              } // statusColors)
            ];

            label = [
              {
                monitor = cfg.defaultMonitor;
                color = fmt.rgba c.mauve "1.0";
                font_size = 120;
                font_family = "RobotoMono Nerd Font";
                position = "0, -80";
                halign = "center";
                valign = "top";
              }
              {
                monitor = cfg.defaultMonitor;
                text = "cmd[update:1000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 echo -e \"$(date +\"%A, %d. %B\")\"";
                color = fmt.rgba c.lavender "0.9";
                font_size = 28;
                font_family = "RobotoMono Nerd Font";
                position = "0, -260";
                halign = "center";
                valign = "top";
              }
              {
                monitor = cfg.defaultMonitor;
                text = "When the issue is labeled \"Bra for nybegynnere\" ༼ ༎ຶ ᆺ ༎ຶ༽";
                color = fmt.rgba c.subtext1 "0.8";
                font_size = 20;
                font_family = "RobotoMono Nerd Font";
                position = "0, -320";
                halign = "center";
                valign = "top";
              }
            ];
          };
        };
      };
    };
}
