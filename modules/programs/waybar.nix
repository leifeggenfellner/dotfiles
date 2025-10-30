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
      ];
      battery = {
        states = {
          good = 95;
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = " {capacity}%";
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
        tooltip-format = "{timeTo} - {capacity}%";
        tooltip-format-charging = "Charging: {timeTo} - {capacity}%";
        tooltip-format-discharging = "Discharging: {timeTo} - {capacity}%";
        tooltip-format-plugged = "Plugged in - {capacity}%";
        tooltip-format-alt = "Battery: {capacity}%";
        on-click = "${system}";
      };

      clock = {
        format = "  {:%a, %d %b, %H:%M}";
        timezone = "Europe/Oslo";
        tooltip = "true";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
        on-click = "${calendar}";
      };

      "custom/launcher" = {
        format = "";
        tooltip = false;
        on-click = "wofi --show drun";
      };

      "hyprland/workspaces" = {
        format = "{icon}";
        format-icons = {
          "1" = ""; # dev
          "2" = ""; # term
          "3" = "󰈹"; # zen
          "4" = ""; # slack
          "5" = ""; # spotify
          "6" = "󰣇"; # system
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
        };
      };

      memory = {
        format = "󰍛 {percentage}%";
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
        on-click = "nm-connection-editor";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "󰝟 {volume}%";
        format-icons = {
          default = [ "󰕿" "󰖀" "󰕾" ];
        };
        scroll-step = 5;
        on-click = "pavucontrol";
        tooltip-format = "Volume: {volume}%";
      };

      temperature = {
        format = " {temperatureC}°C";
        on-click = "${system}";
        tooltip = true;
        critical-threshold = 80;
      };

      tray = {
        icon-size = 18;
        spacing = 8;
        show-passive-items = false;
        reverse-direction = false;
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

      /* Left section - Launcher + Workspaces as connected unit */
      #custom-launcher {
        background: ${palette.background-color};
        color: ${palette.magenta};
        padding: 9px 22px 8px 15px;
        margin: 4px 0px;
        border-radius: 12px;
        font-size: 20px;
        border: 2px solid ${palette.magenta};
        transition: all 0.2s ease;
      }

      #custom-launcher:hover {
        background: linear-gradient(135deg, ${palette.magenta} 0%, ${palette.blue} 100%);
        color: ${palette.background-color};
        border-color: ${palette.magenta};
      }

      #workspaces {
        background-color: ${palette.background-color};
        padding: 4px 8px;
        margin: 4px 6px;
        border-radius: 12px;
        border: 2px solid ${palette.magenta};
      }

      #workspaces button {
        padding: 0px;
        margin: 2px 3px;
        border-radius: 8px;
        color: ${palette.grey};
        background-color: transparent;
        transition: all 0.2s ease;
        font-weight: normal;
        font-size: ${palette.iconsize};
        min-width: 32px;
        min-height: 28px;
        border: 2px solid transparent;
      }

      #workspaces button label {
        padding: 0px 8px;
        font-size: ${palette.iconsize};
      }

      #workspaces button:nth-child(1) label {
        margin-left: -3px;
        margin-top: 1px;
      }

      #workspaces button:nth-child(2) label {
        margin-left: -1px;
        margin-top: 1px;
      }

      #workspaces button:nth-child(3) label {
        margin-left: -3px;
      }

      #workspaces button:nth-child(4) label {
        margin-left: -3px;
      }

      #workspaces button:nth-child(5) label {
        margin-left: -3px;
      }

      #workspaces button:nth-child(6) label {
        margin-left: -3px;
      }

      #workspaces button.active {
        background: linear-gradient(135deg, ${palette.magenta} 0%, ${palette.blue} 100%);
        color: ${palette.background-color};
        font-weight: bold;
        border: 2px solid ${palette.magenta};
      }

      #workspaces button:hover {
        background-color: rgba(137, 180, 250, 0.2);
        color: ${palette.blue};
        border: 2px solid ${palette.blue};
      }

      #workspaces button.active:hover {
        background: linear-gradient(135deg, ${palette.blue} 0%, ${palette.magenta} 100%);
        color: ${palette.background-color};
      }

      #workspaces button.urgent {
        background: linear-gradient(135deg, ${palette.red} 0%, ${palette.orange} 100%);
        color: ${palette.background-color};
        border: 2px solid ${palette.red};
      }

            /* Center - Clock with emphasis */
      #clock {
        background-color: ${palette.background-color};
        color: ${palette.magenta};
        font-weight: bold;
        padding: 8px 16px;
        margin: 4px 6px;
        border-radius: 12px;
        border: 2px solid ${palette.magenta};
        transition: all 0.3s ease;
      }

      #clock:hover {
        background-color: ${palette.magenta};
        color: ${palette.background-color};
        border-color: ${palette.magenta};
      }

      /* Right section - System group connected bar with colored backgrounds */
      #system {
        background-color: transparent;
        padding: 0px;
        margin: 4px 0px;
        border-radius: 12px;
      }

      #temperature,
      #memory,
      #battery,
      #pulseaudio,
      #network {
        padding: 8px 12px;
        margin: 0px;
        border: none;
        transition: all 0.3s ease;
        color: ${palette.background-color};
      }

      /* Temperature - first item with left rounded edge */
      #temperature {
        background-color: ${palette.orange};
        border-radius: 12px 0px 0px 12px;
      }

      #temperature:hover {
        background-color: ${palette.yellow};
      }

      #temperature.critical {
        background-color: ${palette.red};
      }

      /* Memory - middle item */
      #memory {
        background-color: ${palette.cyan};
      }

      #memory:hover {
        background-color: ${palette.blue};
      }

      /* Battery - middle item */
      #battery {
        background-color: ${palette.green};
      }

      #battery:hover {
        background-color: ${palette.cyan};
      }

      #battery.warning {
        background-color: ${palette.yellow};
      }

      #battery.critical {
        background-color: ${palette.red};
      }

      /* Pulseaudio - middle item */
      #pulseaudio {
        background-color: ${palette.magenta};
      }

      #pulseaudio:hover {
        background-color: ${palette.blue};
      }

      #pulseaudio.muted {
        background-color: ${palette.grey};
      }

      /* Network - last item with right rounded edge */
      #network {
        background-color: ${palette.blue};
        border-radius: 0px 12px 12px 0px;
      }

      #network:hover {
        background-color: ${palette.cyan};
      }

      #network.disconnected {
        background-color: ${palette.red};
      }

      /* Tray - separate rounded box */
      #tray {
        background-color: ${palette.background-color};
        padding: 8px 14px;
        margin: 4px 6px 4px 4px;
        border-radius: 12px;
        border: 2px solid ${palette.magenta};
        transition: all 0.3s ease;
      }

      #tray:hover {
        background-color: rgba(203, 166, 247, 0.1);
      }

      #tray > .passive {
        -gtk-icon-effect: dim;
      }

      #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: ${palette.red};
        border-radius: 8px;
      }

      /* Tooltips */
      tooltip {
        background: linear-gradient(135deg, rgba(26, 26, 26, 0.98) 0%, rgba(40, 40, 40, 0.98) 100%);
        border: 2px solid ${palette.magenta};
        border-radius: 10px;
        color: ${palette.grey};
        padding: 8px 12px;
      }

      tooltip label {
        color: ${palette.grey};
      }
    '';
  };
}
