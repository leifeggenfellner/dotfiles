_: {
  flake.homeModules.services-swaync =
    { osConfig, config, lib, ... }:
    let
      c = config.theme.colors;
      s = config.theme.style;
      fmt = import ../themes/_fmt.nix lib;
    in
    {
      # The rice shell owns notifications when enabled — one daemon at a
      # time, org.freedesktop.Notifications has a single owner (ROADMAP Phase 6/7).
      services.swaync = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland" && !(osConfig.rice.enable or false)) {
        enable = true;

        settings = {
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          layer-shell = true;
          layer-shell-cover-screen = true;
          cssPriority = "application";
          notification-window-width = 460;
          notification-body-image-height = 100;
          notification-body-image-width = 200;
          timeout = 7;
          timeout-low = 5;
          timeout-critical = 0;
          transition-time = 200;
          notification-grouping = true;
          fit-to-screen = true;
          control-center-width = 500;
          control-center-layer = "top";
          control-center-margin-top = 8;
          control-center-margin-bottom = 8;
          control-center-margin-right = 8;
          hide-on-clear = true;
          hide-on-action = true;
          keyboard-shortcuts = true;
          image-visibility = "when-available";
          relative-timestamps = true;
          notification-2fa-action = true;
          notification-inline-replies = false;
          widgets = [
            "inhibitors"
            "title"
            "dnd"
            "mpris"
            "volume"
            "notifications"
          ];
          widget-config = {
            title = {
              text = "Notifications";
              clear-all-button = true;
              button-text = "Clear All";
            };
            dnd = {
              text = "Do Not Disturb";
            };
            mpris = {
              image-size = 96;
              blur = true;
            };
            volume = {
              label = "Volume";
              show-per-app = true;
            };
          };
        };

        style = ''
          /* === Root variables === */
          * {
            font-family: "${s.fontMono}", monospace;
            font-size: ${toString s.fontSizeNotification}px;
            color: ${fmt.hex c.text};
          }

          /* === Popup notification window === */
          .notification-row {
            outline: none;
            margin: 4px 0px;
            padding: 0;
          }

          .notification-row:focus,
          .notification-row:hover {
            background: transparent;
          }

          .notification {
            border-radius: ${toString s.rounding}px;
            border: 1px solid rgba(${fmt.rgbComponents c.blue}, 0.4);
            background: rgba(${fmt.rgbComponents c.base}, 0.75);
            box-shadow: 0 4px 16px rgba(${fmt.rgbComponents c.mantle}, 0.5);
            padding: 0;
            margin: 6px 12px;
            transition: all 200ms ease-in-out;
          }

          .notification:hover {
            border-color: rgba(${fmt.rgbComponents c.blue}, 0.7);
            box-shadow: 0 6px 20px rgba(${fmt.rgbComponents c.mantle}, 0.7);
          }

          /* Urgency styles */
          .low-urgency .notification {
            border-color: rgba(${fmt.rgbComponents c.surface1}, 0.4);
          }

          .normal-urgency .notification {
            border-color: rgba(${fmt.rgbComponents c.blue}, 0.4);
          }

          .critical-urgency .notification {
            border: ${toString s.borderWidth}px solid rgba(${fmt.rgbComponents c.red}, 0.7);
            background: rgba(${fmt.rgbComponents c.base}, 0.82);
          }

          /* Notification content */
          .notification-content {
            padding: 12px 16px;
          }

          .summary {
            font-size: ${toString (s.fontSizeNotification + 1)}px;
            font-weight: bold;
            color: ${fmt.hex c.text};
          }

          .body {
            font-size: ${toString (s.fontSizeNotification - 1)}px;
            color: ${fmt.hex c.surface2};
          }

          .time {
            font-size: ${toString (s.fontSizeNotification - 2)}px;
            color: ${fmt.hex c.surface1};
            margin-right: 12px;
          }

          /* Notification icon */
          .notification-image {
            margin: 8px 0px 8px 12px;
            border-radius: ${toString s.roundingSmall}px;
          }

          /* Action buttons */
          .notification-action {
            border-radius: 10px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.6);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.4);
            margin: 4px;
            padding: 6px 12px;
            color: ${fmt.hex c.text};
            transition: all 150ms ease-in-out;
          }

          .notification-action:hover {
            background: rgba(${fmt.rgbComponents c.blue}, 0.2);
            border-color: rgba(${fmt.rgbComponents c.blue}, 0.6);
          }

          .notification-default-action {
            border-radius: ${toString s.rounding}px;
          }

          /* Close button */
          .close-button {
            border-radius: 50%;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.8);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.4);
            color: ${fmt.hex c.text};
            min-width: 24px;
            min-height: 24px;
            margin: 8px;
            transition: all 150ms ease-in-out;
          }

          .close-button:hover {
            background: rgba(${fmt.rgbComponents c.red}, 0.4);
            border-color: rgba(${fmt.rgbComponents c.red}, 0.7);
          }

          /* === Control Center === */
          .control-center {
            border-radius: ${toString s.rounding}px;
            border: 1px solid rgba(${fmt.rgbComponents c.blue}, 0.3);
            background: rgba(${fmt.rgbComponents c.base}, 0.85);
            box-shadow: 0 8px 32px rgba(${fmt.rgbComponents c.mantle}, 0.6);
            margin: 8px;
            padding: 12px;
            transition: all 250ms ease-in-out;
          }

          /* Title widget */
          .widget-title {
            margin: 8px 12px;
          }

          .widget-title > label {
            font-size: 16px;
            font-weight: bold;
            color: ${fmt.hex c.text};
          }

          .widget-title > button {
            border-radius: 10px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.6);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.4);
            color: ${fmt.hex c.text};
            padding: 6px 16px;
            transition: all 150ms ease-in-out;
          }

          .widget-title > button:hover {
            background: rgba(${fmt.rgbComponents c.red}, 0.3);
            border-color: rgba(${fmt.rgbComponents c.red}, 0.6);
          }

          /* DnD widget */
          .widget-dnd {
            margin: 8px 12px;
            padding: 8px;
            border-radius: ${toString s.roundingSmall}px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.4);
          }

          .widget-dnd > switch {
            border-radius: ${toString s.roundingSmall}px;
            background: rgba(${fmt.rgbComponents c.surface1}, 0.6);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.4);
          }

          .widget-dnd > switch:checked {
            background: rgba(${fmt.rgbComponents c.blue}, 0.5);
            border-color: rgba(${fmt.rgbComponents c.blue}, 0.7);
          }

          .widget-dnd > switch slider {
            border-radius: 50%;
            background: ${fmt.hex c.text};
            min-width: 20px;
            min-height: 20px;
            margin: 2px;
          }

          /* MPRIS widget */
          .widget-mpris {
            margin: 8px 12px;
            padding: 12px;
            border-radius: ${toString s.roundingSmall}px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.3);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.3);
          }

          .widget-mpris-player {
            border-radius: ${toString s.roundingSmall}px;
            padding: 8px;
          }

          .widget-mpris > box > button {
            border-radius: 50%;
            min-width: 32px;
            min-height: 32px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.6);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.3);
            transition: all 150ms ease-in-out;
          }

          .widget-mpris > box > button:hover {
            background: rgba(${fmt.rgbComponents c.blue}, 0.3);
          }

          /* Volume widget */
          .widget-volume {
            margin: 8px 12px;
            padding: 8px 12px;
            border-radius: ${toString s.roundingSmall}px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.3);
            border: 1px solid rgba(${fmt.rgbComponents c.surface1}, 0.3);
          }

          .widget-volume scale trough {
            border-radius: 8px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.8);
            min-height: 8px;
          }

          .widget-volume scale trough highlight {
            border-radius: 8px;
            background: rgba(${fmt.rgbComponents c.blue}, 0.8);
          }

          .widget-volume scale slider {
            border-radius: 50%;
            background: ${fmt.hex c.text};
            min-width: 16px;
            min-height: 16px;
          }

          /* Inhibitors widget */
          .widget-inhibitors {
            margin: 8px 12px;
            padding: 8px;
            border-radius: ${toString s.roundingSmall}px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.3);
          }

          /* Notification group headers */
          .notification-group-headers {
            margin: 4px 12px;
            font-weight: bold;
            font-size: ${toString (s.fontSizeNotification - 1)}px;
            color: ${fmt.hex c.surface2};
          }

          .notification-group-collapse-button {
            border-radius: 8px;
            background: rgba(${fmt.rgbComponents c.surface0}, 0.5);
            border: none;
            padding: 4px 8px;
            transition: all 150ms ease-in-out;
          }

          .notification-group-collapse-button:hover {
            background: rgba(${fmt.rgbComponents c.blue}, 0.2);
          }

          /* Empty state */
          .blank-window {
            background: transparent;
          }

          /* Scrollbar */
          scrollbar {
            border-radius: 8px;
          }

          scrollbar slider {
            border-radius: 8px;
            background: rgba(${fmt.rgbComponents c.surface1}, 0.5);
            min-width: 6px;
          }

          scrollbar slider:hover {
            background: rgba(${fmt.rgbComponents c.surface2}, 0.6);
          }
        '';
      };
    };
}
