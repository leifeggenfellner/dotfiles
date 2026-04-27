{ inputs, ... }: {
  flake.homeModules.programs-hyprlock =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      wallpaper = "${config.home.homeDirectory}/Sources/walls-catppuccin-mocha/flower-branch.png";

      # Monitor definitions - match setup-monitors.nix
      workMonitor = "desc:HP Inc. HP 527pu 1H35421YT0"; # Work center
      homeMonitor = "desc:Samsung Electric Company C34J79x HTRM900265"; # Home
      laptopMonitor = "desc:LG Display 0x0791"; # eDP-1 (laptop fallback)

      # Shared label/input builders to avoid repetition
      mkTimeLabel = monitor: fontSize: yOffset: {
        inherit monitor;
        text = "cmd[update:1000] TZ='Europe/Oslo' echo \"<span>$(date +\"%H:%M\")</span>\"";
        color = "rgba(203, 166, 247, 1.0)"; # Mauve
        font_size = fontSize;
        font_family = "RobotoMono Nerd Font";
        position = "0, -${toString yOffset}";
        halign = "center";
        valign = "top";
      };

      mkDateLabel = monitor: fontSize: yOffset: {
        inherit monitor;
        text = "cmd[update:1000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 echo -e \"$(date +\"%A, %d. %B\")\"";
        color = "rgba(180, 190, 254, 0.9)"; # Lavender
        font_size = fontSize;
        font_family = "RobotoMono Nerd Font";
        position = "0, -${toString yOffset}";
        halign = "center";
        valign = "top";
      };

      mkGreetingLabel = monitor: fontSize: yOffset: {
        inherit monitor;
        text = "When the issue is labeled \"Bra for nybegynnere\" ༼ ༎ຶ ᆺ ༎ຶ༽";
        color = "rgba(186, 194, 222, 0.8)"; # Subtext1
        font_size = fontSize;
        font_family = "RobotoMono Nerd Font";
        position = "0, -${toString yOffset}";
        halign = "center";
        valign = "top";
      };

      statusColors = {
        check_color = "rgba(166, 227, 161, 1.0)"; # Green - correct password
        fail_color = "rgba(243, 139, 168, 1.0)"; # Red - wrong password
        bothlock_color = "rgba(249, 226, 175, 1.0)"; # Yellow - caps lock warning
        capslock_color = "rgba(250, 179, 135, 1.0)"; # Peach - caps lock on
        numlock_color = "rgba(137, 220, 235, 1.0)"; # Sky - num lock
      };

      mkInputField = monitor: extraAttrs: {
        inherit monitor;
        size = "280, 50";
        outline_thickness = 2;
        dots_size = 0.16;
        dots_spacing = 0.3;
        dots_center = true;
        outer_color = "rgba(203, 166, 247, 0.8)"; # Mauve border
        inner_color = "rgba(49, 50, 68, 0.8)"; # Surface0 background
        font_color = "rgba(205, 214, 244, 1.0)"; # Text color
        fade_on_empty = false;
        placeholder_text = "hunter2";
        hide_input = false;
        position = "0, 80";
        halign = "center";
        valign = "bottom";
      } // extraAttrs;
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
          default = workMonitor;
          description = "Set the default monitor.";
        };
      };

      config = lib.mkIf (config.program.hyprlock.enable && osConfig.environment.desktop.windowManager == "hyprland") {
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
              (mkInputField workMonitor statusColors)
              (mkInputField homeMonitor statusColors)
              (mkInputField laptopMonitor statusColors)
            ];

            label = [
              # Work center monitor
              (mkTimeLabel workMonitor 120 80)
              (mkDateLabel workMonitor 28 260)
              (mkGreetingLabel workMonitor 20 320)
              # Home monitor
              (mkTimeLabel homeMonitor 120 80)
              (mkDateLabel homeMonitor 28 260)
              (mkGreetingLabel homeMonitor 20 320)
              # Laptop fallback
              (mkTimeLabel laptopMonitor 80 60)
              (mkDateLabel laptopMonitor 18 190)
              (mkGreetingLabel laptopMonitor 16 240)
            ];
          };
        };
      };
    };
}
