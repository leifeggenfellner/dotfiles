{ pkgs, ... }:
pkgs.writeShellScriptBin "handle-monitor" ''
  set -euo pipefail

  DEBOUNCE_PID=""
  SOCKET=""

  cleanup() {
    if [ -n "$DEBOUNCE_PID" ] && kill -0 "$DEBOUNCE_PID" 2>/dev/null; then
      kill "$DEBOUNCE_PID" 2>/dev/null || true
    fi
  }
  trap cleanup EXIT

  reconcile_displays() {
    echo "Reconciling display topology..."
    hyprctl dispatch dpms on 2>/dev/null || true
    thunderbolt-wait || true
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

  detect_socket() {
    local base="$XDG_RUNTIME_DIR/hypr"
    local candidate=""

    if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
      candidate="$base/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
      if [ -S "$candidate" ]; then
        SOCKET="$candidate"
        return 0
      fi
    fi

    candidate=$(find "$base" -maxdepth 2 -type s -name '.socket2.sock' 2>/dev/null | head -n1 || true)
    if [ -n "$candidate" ] && [ -S "$candidate" ]; then
      SOCKET="$candidate"
      return 0
    fi
    return 1
  }

  wait_for_socket() {
    for _ in $(seq 1 120); do
      if detect_socket; then
        return 0
      fi
      sleep 0.1
    done
    echo "Hyprland event socket not found under $XDG_RUNTIME_DIR/hypr" >&2
    return 1
  }

  while true; do
    wait_for_socket || {
      sleep 1
      continue
    }

    echo "Monitoring for display changes on $SOCKET..."
    schedule_reconcile 1

    while read -r line; do
      case "$line" in
        monitoradded*|monitorremoved*)
          echo "Monitor event: $line"
          schedule_reconcile 2
          ;;
      esac
    done < <(${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCKET")

    # Socket stream ended (Hyprland restart or socket churn). Reconnect.
    sleep 0.5
  done
''
