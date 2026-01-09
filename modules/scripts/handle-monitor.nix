{ pkgs, ... }:
let
  socat = "${pkgs.socat}/bin/socat";
  setupMonitors = "setup-monitors";
in
pkgs.writeShellScriptBin "handle-monitor" ''
  handle() {
    case $1 in
      monitoradded*|monitorremoved*)
        echo "Monitor event detected:  $1"
        # Give the system a moment to settle
        sleep 1
        # Re-run monitor setup
        ${setupMonitors}
        ;;
    esac
  }

  echo "Monitoring for display changes..."
  ${socat} - "UNIX-CONNECT: $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/. socket2.sock" | while read -r line; do
    handle "$line"
  done
''
