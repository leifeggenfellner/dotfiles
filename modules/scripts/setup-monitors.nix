{ pkgs, ... }:

pkgs.writeShellScriptBin "setup-monitors" ''
  set -euo pipefail

  JQ=${pkgs. jq}/bin/jq

  MONITOR_LEFT_DESC="HP Inc. HP E45c G5 CNC50212K0"
  MONITOR_RIGHT_DESC="HP Inc. HP E45c G5 CNC1000000"
  MONITOR_HOME_DESC="Samsung Electric Company C34J79x HTRM900265"
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

  echo "Detected monitors:"
  echo "$MONITORS_JSON" | $JQ -r '.[].description'

  if has_desc "$MONITOR_HOME_DESC"; then
    echo "Home setup detected"

    HOME_MON=$(name_of "$MONITOR_HOME_DESC")
    echo "Samsung output name: $HOME_MON"

    hyprctl keyword monitor "$LAPTOP,1920x1200@60,0x0,1"
    hyprctl keyword monitor "$HOME_MON,3440x1440@60,1920x0,1"

    # Move existing workspaces first
    hyprctl dispatch moveworkspacetomonitor 1 "$HOME_MON"
    hyprctl dispatch moveworkspacetomonitor 2 "$HOME_MON"
    for i in {3..6}; do
      hyprctl dispatch moveworkspacetomonitor "$i" "$LAPTOP"
    done

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:$HOME_MON"
    hyprctl keyword workspace "2,monitor:$HOME_MON"
    hyprctl keyword workspace "3,monitor:$LAPTOP"
    hyprctl keyword workspace "4,monitor:$LAPTOP"
    hyprctl keyword workspace "5,monitor:$LAPTOP"
    hyprctl keyword workspace "6,monitor:$LAPTOP"

  elif has_desc "$MONITOR_LEFT_DESC" && has_desc "$MONITOR_RIGHT_DESC"; then
    echo "Office setup detected"

    LEFT_MON=$(name_of "$MONITOR_LEFT_DESC")
    RIGHT_MON=$(name_of "$MONITOR_RIGHT_DESC")
    echo "Left office monitor: $LEFT_MON, Right office monitor: $RIGHT_MON"

    hyprctl keyword monitor "$LAPTOP,disable"
    hyprctl keyword monitor "$LEFT_MON,2560x1440@60,0x0,1"
    hyprctl keyword monitor "$RIGHT_MON,2560x1440@60,2560x0,1"

    # Move existing workspaces first
    hyprctl dispatch moveworkspacetomonitor 1 "$LEFT_MON"
    hyprctl dispatch moveworkspacetomonitor 4 "$LEFT_MON"
    hyprctl dispatch moveworkspacetomonitor 6 "$LEFT_MON"

    hyprctl dispatch moveworkspacetomonitor 2 "$RIGHT_MON"
    hyprctl dispatch moveworkspacetomonitor 3 "$RIGHT_MON"
    hyprctl dispatch moveworkspacetomonitor 5 "$RIGHT_MON"

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:$LEFT_MON"
    hyprctl keyword workspace "4,monitor:$LEFT_MON"
    hyprctl keyword workspace "6,monitor:$LEFT_MON"

    hyprctl keyword workspace "2,monitor:$RIGHT_MON"
    hyprctl keyword workspace "3,monitor:$RIGHT_MON"
    hyprctl keyword workspace "5,monitor:$RIGHT_MON"

  else
    echo "Laptop-only setup"

    hyprctl keyword monitor "$LAPTOP,preferred,0x0,1"

    for i in {1..10}; do
      hyprctl keyword workspace "$i,monitor:$LAPTOP"
    done
  fi

  echo "Monitor setup complete"
''
