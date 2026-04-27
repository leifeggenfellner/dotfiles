{ pkgs
, monitorHome ? ""
, monitorWorkCenter ? ""
, monitorWorkRight ? ""
, ...
}:

pkgs.writeShellScriptBin "setup-monitors" ''
  set -euo pipefail

  JQ=${pkgs.jq}/bin/jq

  MONITOR_HOME_DESC="${monitorHome}"
  MONITOR_WORK_CENTER_DESC="${monitorWorkCenter}"
  MONITOR_WORK_RIGHT_DESC="${monitorWorkRight}"
  LAPTOP="eDP-1"

  MONITORS_JSON=$(hyprctl monitors -j)

  has_desc() {
    echo "$MONITORS_JSON" | $JQ -e --arg d "$1" \
      '.[] | select(.description | contains($d))' >/dev/null
  }

  name_of() {
    echo "$MONITORS_JSON" | $JQ -r --arg d "$1" \
      '.[] | select(.description | contains($d)) | .name'
  }

  move_ws() {
    hyprctl dispatch moveworkspacetomonitor "$1" "$2" 2>/dev/null || true
  }

  echo "Detected monitors:"
  echo "$MONITORS_JSON" | $JQ -r '.[].description'

  if has_desc "$MONITOR_HOME_DESC"; then
    echo "Home setup detected"

    HOME_MON=$(name_of "$MONITOR_HOME_DESC")
    echo "Samsung output name: $HOME_MON"

    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"
    hyprctl keyword monitor "$HOME_MON,3440x1440@60,1920x0,1"

    # Move existing workspaces first
    move_ws 1 "$HOME_MON"
    move_ws 2 "$HOME_MON"
    for i in {3..6}; do
      move_ws "$i" "$LAPTOP"
    done

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:$HOME_MON"
    hyprctl keyword workspace "2,monitor:$HOME_MON"
    hyprctl keyword workspace "3,monitor:$LAPTOP"
    hyprctl keyword workspace "4,monitor:$LAPTOP"
    hyprctl keyword workspace "5,monitor:$LAPTOP"
    hyprctl keyword workspace "6,monitor:$LAPTOP"

  elif has_desc "$MONITOR_WORK_CENTER_DESC" && has_desc "$MONITOR_WORK_RIGHT_DESC"; then
    echo "Work setup detected"

    CENTER_MON=$(name_of "$MONITOR_WORK_CENTER_DESC")
    RIGHT_MON=$(name_of "$MONITOR_WORK_RIGHT_DESC")
    echo "Center monitor: $CENTER_MON, Right monitor: $RIGHT_MON"

    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"
    hyprctl keyword monitor "$CENTER_MON,2560x1440@60,1920x0,1"
    hyprctl keyword monitor "$RIGHT_MON,2560x1440@60,4480x0,1"

    # Move existing workspaces first
    move_ws 1 "$CENTER_MON"
    move_ws 6 "$CENTER_MON"

    move_ws 3 "$RIGHT_MON"

    move_ws 2 "$LAPTOP"
    move_ws 4 "$LAPTOP"
    move_ws 5 "$LAPTOP"

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:$CENTER_MON"
    hyprctl keyword workspace "6,monitor:$CENTER_MON"

    hyprctl keyword workspace "3,monitor:$RIGHT_MON"

    hyprctl keyword workspace "2,monitor:$LAPTOP"
    hyprctl keyword workspace "4,monitor:$LAPTOP"
    hyprctl keyword workspace "5,monitor:$LAPTOP"

  else
    echo "Laptop-only setup"

    hyprctl keyword monitor "$LAPTOP,preferred,0x0,1"

    for i in {1..10}; do
      hyprctl keyword workspace "$i,monitor:$LAPTOP"
    done
  fi

  echo "Monitor setup complete"
''
