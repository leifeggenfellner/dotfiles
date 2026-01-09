{ pkgs, ... }:

pkgs.writeShellScriptBin "setup-monitors" ''
  # Monitor descriptors
  MONITOR_LEFT="desc:HP Inc. HP E45c G5 CNC50212K0"
  MONITOR_RIGHT="desc: HP Inc. HP E45c G5 CNC1000000"
  MONITOR_HOME="desc:Samsung Electric Company C34J79x HTRM900265"
  LAPTOP="eDP-1"

  # Get list of connected monitors
  CONNECTED=$(hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r '.[].name')

  echo "Connected monitors:  $CONNECTED"

  # Detect which monitors are connected
  HAS_HP_LEFT=$(echo "$CONNECTED" | grep -c "$(hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r --arg desc "$MONITOR_LEFT" '. [] | select(.description | contains($desc)) | .name')" || true)
  HAS_HP_RIGHT=$(echo "$CONNECTED" | grep -c "$(hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r --arg desc "$MONITOR_RIGHT" '.[] | select(.description | contains($desc)) | .name')" || true)
  HAS_SAMSUNG=$(echo "$CONNECTED" | grep -c "$(hyprctl monitors all -j | ${pkgs.jq}/bin/jq -r --arg desc "$MONITOR_HOME" '.[] | select(.description | contains($desc)) | .name')" || true)

  # Configure based on what's connected
  if [ "$HAS_SAMSUNG" -gt 0 ]; then
    echo "Home setup detected (Samsung ultrawide)"

    # Samsung ultrawide at native resolution
    hyprctl keyword monitor "$MONITOR_HOME,3440x1440@60,1920x0,1"

    # Laptop to the LEFT of Samsung
    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"

    # Assign workspaces
    hyprctl keyword workspace "1, monitor:$MONITOR_HOME"
    hyprctl keyword workspace "2, monitor:$MONITOR_HOME"
    hyprctl keyword workspace "3, monitor:$LAPTOP"
    hyprctl keyword workspace "4, monitor:$LAPTOP"
    hyprctl keyword workspace "5, monitor:$LAPTOP"
    hyprctl keyword workspace "6, monitor:$LAPTOP"

  elif [ "$HAS_HP_LEFT" -gt 0 ] && [ "$HAS_HP_RIGHT" -gt 0 ]; then
    echo "Office setup detected (Dual HP monitors)"

    # Laptop on the LEFT
    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"

    # HP left monitor (middle position)
    hyprctl keyword monitor "$MONITOR_LEFT,2560x1440@60,1920x0,1"

    # HP right monitor (rightmost position)
    hyprctl keyword monitor "$MONITOR_RIGHT,2560x1440@60,4480x0,1"

    # Assign workspaces
    hyprctl keyword workspace "1, monitor: $MONITOR_LEFT"
    hyprctl keyword workspace "2, monitor:$MONITOR_LEFT"
    hyprctl keyword workspace "3, monitor:$MONITOR_RIGHT"
    hyprctl keyword workspace "4, monitor:$MONITOR_RIGHT"
    hyprctl keyword workspace "5, monitor:$MONITOR_RIGHT"
    hyprctl keyword workspace "6, monitor:$MONITOR_LEFT"

  else
    echo "Laptop-only setup"

    # Just laptop screen
    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"

    # All workspaces on laptop
    for i in {1.. 6}; do
      hyprctl keyword workspace "$i, monitor: $LAPTOP"
    done
  fi

  echo "Monitor setup complete!"
''
