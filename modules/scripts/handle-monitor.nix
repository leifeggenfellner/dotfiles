{ pkgs, ... }:

pkgs.writeShellScriptBin "handle-monitor" ''
  set -euo pipefail

  SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

  echo "Monitoring for display changes..."

  ${pkgs.socat}/bin/socat - "UNIX-CONNECT:$SOCKET" | while read -r line; do
    case "$line" in
      monitoradded*|monitorremoved*)
        echo "Monitor event: $line"
        sleep 1
        setup-monitors
        ;;
    esac
  done
''
