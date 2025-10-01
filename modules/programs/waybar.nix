{ lib
, pkgs
, config
, osConfig
, ...
}:
let
  fontSize = "14px";
  iconSize = "17px";
  opacity = "0.8";
  palette = {
    font = "RobotoMono Nerd Font";
    fontsize = fontSize;
    iconsize = iconSize;
    background-color = "rgba(26, 26, 26, ${opacity})";
    background_border-frame = "#${config.colorScheme.palette.base02}";

    blue = "#${config.colorScheme.palette.base0D}";
    cyan = "#${config.colorScheme.palette.base0C}";
    green = "#${config.colorScheme.palette.base0B}";
    grey = "#${config.colorScheme.palette.base04}";
    magenta = "#${config.colorScheme.palette.base0E}";
    orange = "#${config.colorScheme.palette.base09}";
    red = "#${config.colorScheme.palette.base08}";
    yellow = "#${config.colorScheme.palette.base0A}";
  };
  calendar = "${pkgs.gnome-calendar}/bin/gnome-calendar";
  lockScreen = "${pkgs.hyprlock}/bin/hyprlock";
  system = "${pkgs.gnome-system-monitor}/bin/gnome-system-monitor";
in
{
  programs.waybar = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
    enable = true;
    package = pkgs.waybar.overrideAttrs (oa: {
      mesonFlags = (oa.mesonFlags or [ ]) ++ [ "-Dexperimental=true" ];
    });
    systemd.enable = true;
    settings.mainBar = {
      position = "top";
      layer = "top";
      height = 36;
      margin-top = 6;
      margin-bottom = 0;
      margin-left = 8;
      margin-right = 8;
      spacing = 8;
      modules-left = [
        "custom/launcher"
        "hyprland/workspaces"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "tray"
        "group/system"
        "custom/lock"
      ];
      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon}";
        format-charging = "󰂄";
        format-plugged = "";
        format-alt = "{icon} {capacity}%";
        format-icons = [
          "󰂎" # 0-10%
          "󰁺" # 10-20%
          "󰁻" # 20-30%
          "󰁼" # 30-40%
          "󰁽" # 40-50%
          "󰁾" # 50-60%
          "󰁿" # 60-70%
          "󰂀" # 70-80%
          "󰂁" # 80-90%
          "󰂂" # 90-95%
          "󰁹" # 95-100%
        ];
        tooltip-format = "Battery: {capacity}% - {time}";
      };

      clock = {
        format = " {:%a, %d %b, %I:%M %p}";
        tooltip = "true";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        format-alt = " {:%d%m}";
        on-click = "${calendar}";
      };

      "custom/launcher" = {
        format = "";
        tooltip = false;
        on-click = "wofi --show drun";
      };

      "custom/lock" = {
        "format" = "󰌾";
        "tooltip" = true;
        "tooltip-format" = "Lock Screen";
        "on-click" = "${lockScreen}";
      };

      "hyprland/workspaces" = {
        format = "{name}";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          "6" = "";
          "7" = "";
          "8" = "";
          "9" = "";
          default = "";
        };
        on-click = "activate";
        all-outputs = true;
        active-only = false;
        persistent-workspaces = {
          "1" = [ ];
          "2" = [ ];
          "3" = [ ];
          "4" = [ ];
          "5" = [ ];
          "6" = [ ];
          "7" = [ ];
          "8" = [ ];
          "9" = [ ];
        };
      };

      memory = {
        format = "󰍛 {percentage}%";
        format-alt = "󰍛 {used:0.1f}G";
        on-click = "${system}";
        interval = 5;
        tooltip-format = "Memory: {used:0.1f}G / {total:0.1f}G";
      };

      network = {
        format-wifi = " ";
        format-ethernet = "󰈀 ";
        tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
        format-linked = "󰈀 (No IP)";
        format-disconnected = "󰖪 ";
        format-alt = " {essid}";
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "{icon}";
        format-muted = "󰝟";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        scroll-step = 5;
        on-click = "pavucontrol";
        tooltip-format = "Volume: {volume}%";
      };

      temperature = {
        format = " {temperatureC}°C";
        format-alt = "";
        on-click = "${system}";
        tooltip = true;
        critical-threshold = 80;
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };

      "group/system" = {
        "orientation" = "horizontal";
        "modules" = [
          "temperature"
          "memory"
          "battery"
          "pulseaudio"
          "network"
        ];
      };
    };
    style = ''
      * {
          border: none;
          border-radius: 0px;
          font-family: ${palette.font};
          font-size: ${palette.fontsize};
          font-weight: bold;
          min-height: 0;
      }

      window#waybar {
         background-color: transparent;
      }


      /* Individual module styling */
      #workspaces,
      #clock,
      #tray,
      #system,
      #custom-launcher,
      "custom-lock {
        background-color: ${palette.background-color};
        border-radius: 12px;
        margin: 4px 2px;
        padding: 4px 12px;
        border: 2px solid ${palette.magenta};
      }

      /* Workspace styling */
      #workspaces {
        padding: 2px 4px;
      }

      #workspaces button {
        padding: 4px 8px;
        margin: 2px;
        border-radius: 8px;
        color: ${palette.grey};
        background-color: transparent;
        transition: all 0.3s ease;
      }

      #workspaces button.active {
        background-color: ${palette.magenta};
        color: #${config.colorScheme.palette.base00};
        font-weight: bold;
      }


      #workspaces button:hover {
        background-color: ${palette.blue};
        color: #${config.colorScheme.palette.base00};
      }

      #workspaces button.urgent {
        background-color: ${palette.red};
        color: #${config.colorScheme.palette.base00};
      }

      /* Launcher styling */
      #custom-launcher {
        font-size: 18px;
        color: ${palette.magenta};
        padding: 6px 12px;
      }

      #custom-launcher:hover {
        background-color: ${palette.magenta};
        color: #${config.colorScheme.palette.base00};
      }

      /* Lock button styling */
      #custom-lock {
        color: ${palette.green};
        padding: 6px 12px;
      }

      #custom-lock:hover {
        background-color: ${palette.green};
        color: #${config.colorScheme.palette.base00};
      }

      /* Clock styling */
      #clock {
        color: ${palette.blue};
        font-weight: bold;
        padding: 6px 16px;
      }

      /* System group styling */
      #system {
        background-color: rgba(180, 142, 173, 0.15);
        border-color: ${palette.magenta};
        padding: 4px 8px;
      }

      /* Individual system module colors */
      #battery {
        color: ${palette.green};
        margin: 0 4px;
      }
      #battery.warning {
        color: ${palette.yellow};
      }
      #battery.critical {
        color: ${palette.red};
      }

      #memory {
        color: ${palette.cyan};
        margin: 0 4px;
      }

      #network {
        color: ${palette.blue};
        margin: 0 4px;
      }
      #network.disconnected {
        color: ${palette.red};
      }

      #pulseaudio {
        color: ${palette.magenta};
        margin: 0 4px;
      }
      #pulseaudio.muted {
        color: ${palette.grey};
      }

      #temperature {
        color: ${palette.orange};
        margin: 0 4px;
      }
      #temperature.critical {
        color: ${palette.red};
      }

      /* Tray styling */
      #tray {
        background-color: rgba(180, 142, 173, 0.2);
        border-color: ${palette.magenta};
        padding: 6px 12px;
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: ${palette.red};
      }

      /* Hover effects for all modules */
      #clock:hover,
      #system:hover,
      #tray:hover {
        background-color: rgba(180, 142, 173, 0.3);
      }

      /* Tooltips */
      tooltip {
        background-color: rgba(26, 26, 26, 0.95);
        border: 2px solid ${palette.magenta};
        border-radius: 8px;
        color: ${palette.grey};
      }
    '';
  };
}
