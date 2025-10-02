{ osConfig
, inputs
, config
, pkgs
, lib
, ...
}:
let
  wallpaper = "${config.home.homeDirectory}/Sources/walls-catppuccin-mocha/flower-branch.png";

  # Monitor definitions
  primaryMonitor = "desc:HP Inc. HP E45c G5 CNC50212K0"; # ID 1 (left monitor)
  fallbackMonitor = "desc:LG Display 0x0791"; # eDP-1 (laptop)
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
      default = primaryMonitor;
      description = "Set the default monitor.";
    };
  };

  config = lib.mkIf (config.program.hyprlock.enable && osConfig.environment.desktop.windowManager == "hyprland") {
    programs.hyprlock = {
      enable = true;
      package = inputs.hyprlock.packages.${pkgs.system}.hyprlock;

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
          # Primary input field on left external monitor
          {
            monitor = primaryMonitor;
            size = "320, 60";
            outline_thickness = 2;
            dots_size = 0.15;
            dots_spacing = 0.3;
            dots_center = true;

            # Default state colors
            outer_color = "rgba(203, 166, 247, 0.8)"; # Mauve border
            inner_color = "rgba(49, 50, 68, 0.8)"; # Surface0 background
            font_color = "rgba(205, 214, 244, 1.0)"; # Text color

            check_color = "rgba(166, 227, 161, 1.0)"; # Green - correct password
            fail_color = "rgba(243, 139, 168, 1.0)"; # Red - wrong password
            bothlock_color = "rgba(249, 226, 175, 1.0)"; # Yellow - caps lock warning
            capslock_color = "rgba(250, 179, 135, 1.0)"; # Peach - caps lock on
            numlock_color = "rgba(137, 220, 235, 1.0)"; # Sky - num lock

            # Validation colors
            fade_on_empty = false;
            placeholder_text = "hunter2";
            hide_input = false;
            position = "0, -120";
            halign = "center";
            valign = "center";
          }
          # Fallback input field on laptop screen
          {
            monitor = fallbackMonitor;
            size = "320, 60";
            outline_thickness = 2;
            dots_size = 0.25;
            dots_spacing = 0.3;
            dots_center = true;
            outer_color = "rgba(203, 166, 247, 0.8)"; # Mauve border
            inner_color = "rgba(49, 50, 68, 0.8)"; # Surface0 background
            font_color = "rgba(205, 214, 244, 1.0)"; # Text color
            fade_on_empty = false;
            placeholder_text = "hunter2";
            hide_input = false;
            position = "0, -100";
            halign = "center";
            valign = "center";
          }
        ];

        label = [
          # Time label on primary monitor - using Mauve
          {
            monitor = primaryMonitor;
            text = "cmd[update:1000] TZ='Europe/Oslo' echo \"<span>$(date +\"%H:%M\")</span>\"";
            color = "rgba(203, 166, 247, 1.0)"; # Mauve
            font_size = 120;
            font_family = "RobotoMono Nerd Font";
            position = "0, 120";
            halign = "center";
            valign = "center";
          }
          # Date label on primary monitor - using Lavender
          {
            monitor = primaryMonitor;
            text = "cmd[update:1000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 echo -e \"$(date +\"%A, %d. %B\")\"";
            color = "rgba(180, 190, 254, 0.9)"; # Lavender
            font_size = 28;
            font_family = "RobotoMono Nerd Font";
            position = "0, 30";
            halign = "center";
            valign = "center";
          }
          # User greeting on primary monitor - using Subtext1
          {
            monitor = primaryMonitor;
            text = "It's slaving time ༼ ༎ຶ ᆺ ༎ຶ༽";
            color = "rgba(186, 194, 222, 0.8)"; # Subtext1
            font_size = 20;
            font_family = "RobotoMono Nerd Font";
            position = "0, -50"; # Below input field
            halign = "center";
            valign = "center";
          }
          # Fallback time label on laptop screen
          {
            monitor = fallbackMonitor;
            text = "cmd[update:1000] TZ='Europe/Oslo' echo \"<span>$(date +\"%H:%M\")</span>\"";
            color = "rgba(203, 166, 247, 1.0)"; # Mauve
            font_size = 80;
            font_family = "RobotoMono Nerd Font";
            position = "0, 100";
            halign = "center";
            valign = "center";
          }
          # Fallback date label on laptop screen
          {
            monitor = fallbackMonitor;
            text = "cmd[update:1000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 echo -e \"$(date +\"%A, %d. %B\")\"";
            color = "rgba(180, 190, 254, 0.9)"; # Lavender
            font_size = 18;
            font_family = "RobotoMono Nerd Font";
            position = "0, 50";
            halign = "center";
            valign = "center";
          }
          # Fallback user greeting on laptop screen
          {
            monitor = fallbackMonitor;
            text = "It's slaving time ༼ ༎ຶ ᆺ ༎ຶ༽";
            color = "rgba(186, 194, 222, 0.8)";
            font_size = 16;
            font_family = "RobotoMono Nerd Font";
            position = "0, -40";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };
  };
}
