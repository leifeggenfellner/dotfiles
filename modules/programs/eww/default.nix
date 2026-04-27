_:
{
  flake.homeModules.programs-eww =
    { lib
    , pkgs
    , config
    , osConfig
    , ...
    }:
    let
      inherit (config.colorScheme) palette;

      # === Helper Scripts ===
      eww-workspaces = pkgs.writeShellApplication {
        name = "eww-workspaces";
        runtimeInputs = with pkgs; [ hyprland jq socat coreutils ];
        text = ''
          get_workspaces() {
            active=$(hyprctl activeworkspace -j | jq '.id')
            # Always show 1-6, plus any higher active workspaces
            ids=$(hyprctl workspaces -j | jq -r '.[].id | select(. > 0)' | sort -n)
            all_ids=$(printf '%s\n' $(seq 1 6) "$ids" | sort -n -u)
            for i in $all_ids; do
              if [ "$i" = "$active" ]; then
                echo -n "{\"id\":$i,\"active\":true},"
              else
                echo -n "{\"id\":$i,\"active\":false},"
              fi
            done | sed 's/,$//'
          }

          # Initial output
          echo "[$(get_workspaces)]"

          # Listen for workspace changes
          socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r _; do
            echo "[$(get_workspaces)]"
          done
        '';
      };

      eww-volume = pkgs.writeShellApplication {
        name = "eww-volume";
        runtimeInputs = with pkgs; [ wireplumber jq coreutils ];
        text = ''
          get_volume() {
            vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
            muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | grep -c MUTED || true)
            echo "{\"volume\":$vol,\"muted\":$muted}"
          }

          get_volume

          # Poll every 1s for volume changes
          while sleep 1; do
            get_volume
          done
        '';
      };

      eww-network = pkgs.writeShellApplication {
        name = "eww-network";
        runtimeInputs = with pkgs; [ networkmanager coreutils gnugrep ];
        text = ''
          get_network() {
            wifi=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
            if [ -n "$wifi" ]; then
              echo "{\"status\":\"connected\",\"ssid\":\"$wifi\",\"type\":\"wifi\"}"
            elif nmcli -t -f TYPE,STATE con show --active | grep -q "ethernet:activated"; then
              echo "{\"status\":\"connected\",\"ssid\":\"Ethernet\",\"type\":\"ethernet\"}"
            else
              echo "{\"status\":\"disconnected\",\"ssid\":\"\",\"type\":\"none\"}"
            fi
          }

          get_network
          while sleep 5; do
            get_network
          done
        '';
      };

      eww-battery = pkgs.writeShellApplication {
        name = "eww-battery";
        runtimeInputs = with pkgs; [ coreutils ];
        text = ''
          get_battery() {
            if [ -d /sys/class/power_supply/BAT0 ]; then
              capacity=$(cat /sys/class/power_supply/BAT0/capacity)
              status=$(cat /sys/class/power_supply/BAT0/status)
              echo "{\"capacity\":$capacity,\"status\":\"$status\",\"present\":true}"
            else
              echo "{\"capacity\":100,\"status\":\"Full\",\"present\":false}"
            fi
          }

          get_battery
          while sleep 10; do
            get_battery
          done
        '';
      };

      eww-notifications = pkgs.writeShellApplication {
        name = "eww-notifications";
        runtimeInputs = with pkgs; [ swaynotificationcenter coreutils jq ];
        text = ''
          get_notifs() {
            count=$(swaync-client -c 2>/dev/null || echo "0")
            dnd=$(swaync-client -D 2>/dev/null || echo "false")
            echo "{\"count\":$count,\"dnd\":$dnd}"
          }

          get_notifs
          while sleep 2; do
            get_notifs
          done
        '';
      };

      eww-brightness = pkgs.writeShellApplication {
        name = "eww-brightness";
        runtimeInputs = with pkgs; [ brightnessctl coreutils gawk ];
        text = ''
          get_brightness() {
            val=$(brightnessctl -m | awk -F, '{print $4}' | tr -d '%')
            echo "{\"brightness\":$val}"
          }

          get_brightness
          while sleep 2; do
            get_brightness
          done
        '';
      };

      # === eww SCSS — flat CSS, no SCSS variables, Tokyo structure ===
      ewwScss = ''
        * { all: unset; }

        .eww_bar {
          background-color: #${palette.base00};
          padding: .3rem;
          font-family: "RobotoMono Nerd Font";
          font-size: 16px;
        }

        .launcher_icon {
          color: #${palette.base0C};
          font-size: 2.2em;
          padding: 1rem 0 1rem 0;
          text-align: center;
        }

        .works {
          padding: .2rem .7rem .2rem .7rem;
          background-color: #${palette.base02};
          border-radius: 5px;
        }

        .ws-active,
        .ws-inactive {
          margin: .55rem 0 .55rem 0;
          font-size: 1.8em;
          text-align: center;
        }

        .ws-inactive {
          color: #${palette.base04};
        }

        .ws-active {
          color: #${palette.base05};
        }

        .control {
          padding: .5rem;
          background-color: #${palette.base02};
          border-radius: 5px;
        }

        .bat {
          font-size: 1.3em;
          color: #${palette.base0D};
          text-align: center;
        }

        .wifi-icon {
          font-size: 1.5em;
          margin-bottom: .2rem;
          color: #${palette.base0E};
          text-align: center;
        }

        .brightness-icon {
          font-size: 1.5em;
          margin: .2rem 0 .2rem 0;
          color: #${palette.base0A};
          text-align: center;
        }

        .volume-icon {
          font-size: 1.5em;
          margin: .2rem 0 .2rem 0;
          color: #${palette.base0B};
          text-align: center;
        }

        .notif-icon {
          font-size: 1.5em;
          margin: .2rem 0 .2rem 0;
          color: #${palette.base05};
          text-align: center;
        }

        .has-notifs {
          color: #${palette.base09};
        }

        scale trough {
          all: unset;
          background-color: #${palette.base00};
          border-radius: 5px;
          min-height: 80px;
          min-width: 10px;
          margin: .3rem 0 .3rem 0;
        }

        .bribar trough highlight {
          background-color: #${palette.base0A};
          border-radius: 5px;
        }

        .volbar trough highlight {
          background-color: #${palette.base0B};
          border-radius: 5px;
        }

        .time {
          font-weight: bold;
          font-size: 1.2em;
          background-color: #${palette.base02};
          color: #${palette.base05};
          border-radius: 5px;
          padding: .7rem 0 .5rem 0;
          margin: .5rem 0 .5rem 0;
          text-align: center;
        }

        .powermenu {
          font-size: 1.4em;
          font-weight: bold;
        }

        .btn-shutdown,
        .btn-reboot,
        .btn-lock,
        .btn-logout {
          padding: .5rem .2rem .3rem .2rem;
          text-align: center;
        }

        .btn-shutdown {
          margin-bottom: .5rem;
          color: #${palette.base08};
        }

        .btn-reboot {
          color: #${palette.base0A};
        }

        .btn-lock {
          color: #${palette.base0D};
        }

        .btn-logout {
          color: #${palette.base0E};
        }
      '';
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home.packages = [
          pkgs.eww
          pkgs.brightnessctl
          pkgs.networkmanager_dmenu
          eww-workspaces
          eww-volume
          eww-brightness
          eww-network
          eww-battery
          eww-notifications
        ];

        xdg.configFile = {
          "eww/eww.yuck".source = ./eww.yuck;
          "eww/eww.scss".text = ewwScss;
          "networkmanager-dmenu/config.ini".text = ''
            [dmenu]
            dmenu_command = wofi --dmenu -i
          '';
        };
      };
    };
}
