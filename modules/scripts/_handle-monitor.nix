{ pkgs, ... }:
let
  awww = "${pkgs.awww}/bin/awww";
in
pkgs.writeShellScriptBin "handle-monitor" ''
  set -euo pipefail

  SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  PERSIST_WP="$HOME/.config/wallpaper/current"

  DEBOUNCE_PID=""

  restore_wallpaper() {
    if [ -f "$PERSIST_WP" ]; then
      WP=$(cat "$PERSIST_WP")
      if [ -f "$WP" ]; then
        # awww img sets wallpaper on ALL outputs by default
        ${awww} img "$WP" \
          --transition-type fade \
          --transition-duration 1.0 \
          --transition-fps 60 2>/dev/null || true
      fi
    fi
  }

  on_monitor_change() {
    # Wake any DPMS-off monitors
    hyprctl dispatch dpms on 2>/dev/null || true

    # Reconfigure layout
    setup-monitors

    # Restore wallpaper to all outputs (including new ones)
    sleep 0.5
    restore_wallpaper
  }

  echo "Monitoring for display changes..."

  ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCKET" | while read -r line; do
    case "$line" in
      monitoradded*|monitorremoved*)
        echo "Monitor event: $line"
        # Kill any pending debounced run
        if [ -n "$DEBOUNCE_PID" ] && kill -0 "$DEBOUNCE_PID" 2>/dev/null; then
          kill "$DEBOUNCE_PID" 2>/dev/null || true
        fi
        # Debounce: wait for events to settle before running setup
        (sleep 2 && on_monitor_change) &
        DEBOUNCE_PID=$!
        ;;
    esac
  done
''
