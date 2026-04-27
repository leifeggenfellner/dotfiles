{ pkgs, ... }:

pkgs.writeShellScriptBin "handle-monitor" ''
  set -euo pipefail

  SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

  DEBOUNCE_PID=""

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
        (sleep 2 && setup-monitors) &
        DEBOUNCE_PID=$!
        ;;
    esac
  done
''
