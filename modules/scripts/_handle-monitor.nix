{ pkgs, ... }:
pkgs.writeShellScriptBin "handle-monitor" ''
  set -euo pipefail

  SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

  DEBOUNCE_PID=""

  cleanup() {
    if [ -n "$DEBOUNCE_PID" ] && kill -0 "$DEBOUNCE_PID" 2>/dev/null; then
      kill "$DEBOUNCE_PID" 2>/dev/null || true
    fi
  }
  trap cleanup EXIT

  reconcile_displays() {
    echo "Reconciling display topology..."
    hyprctl dispatch dpms on 2>/dev/null || true
    setup-monitors || true
    wallpaper-restore || true
  }

  schedule_reconcile() {
    local delay="''${1:-2}"
    if [ -n "$DEBOUNCE_PID" ] && kill -0 "$DEBOUNCE_PID" 2>/dev/null; then
      kill "$DEBOUNCE_PID" 2>/dev/null || true
    fi
    (sleep "$delay" && reconcile_displays) &
    DEBOUNCE_PID=$!
  }

  wait_for_socket() {
    for _ in $(seq 1 50); do
      [ -S "$SOCKET" ] && return 0
      sleep 0.1
    done
    echo "Hyprland event socket not found: $SOCKET" >&2
    return 1
  }

  wait_for_socket || exit 0

  echo "Monitoring for display changes..."
  schedule_reconcile 1

  while read -r line; do
    case "$line" in
      monitoradded*|monitorremoved*)
        echo "Monitor event: $line"
        schedule_reconcile 2
        ;;
    esac
  done < <(${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCKET")
''
