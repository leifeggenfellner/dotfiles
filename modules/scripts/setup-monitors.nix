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

  echo "Detected monitors:"
  echo "$MONITORS_JSON" | $JQ -r '.[].description'

  if has_desc "$MONITOR_HOME_DESC"; then
    echo "Home setup detected"

    hyprctl keyword monitor "desc:$MONITOR_HOME_DESC,3440x1440@60,0x0,1"
    hyprctl keyword monitor "$LAPTOP,1920x1200@60,3440x0,1"

    # Move existing workspaces first
    hyprctl dispatch moveworkspacetomonitor 1 "desc: $MONITOR_HOME_DESC"
    hyprctl dispatch moveworkspacetomonitor 2 "desc:$MONITOR_HOME_DESC"
    for i in {3..6}; do
      hyprctl dispatch moveworkspacetomonitor "$i" "$LAPTOP"
    done

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:desc: $MONITOR_HOME_DESC"
    hyprctl keyword workspace "2,monitor:desc:$MONITOR_HOME_DESC"
    hyprctl keyword workspace "3,monitor:$LAPTOP"
    hyprctl keyword workspace "4,monitor:$LAPTOP"
    hyprctl keyword workspace "5,monitor:$LAPTOP"
    hyprctl keyword workspace "6,monitor:$LAPTOP"

  elif has_desc "$MONITOR_LEFT_DESC" && has_desc "$MONITOR_RIGHT_DESC"; then
    echo "Office setup detected"

    hyprctl keyword monitor "$LAPTOP,disable"
    hyprctl keyword monitor "desc: $MONITOR_LEFT_DESC,2560x1440@60,0x0,1"
    hyprctl keyword monitor "desc: $MONITOR_RIGHT_DESC,2560x1440@60,2560x0,1"

    # Move existing workspaces first
    hyprctl dispatch moveworkspacetomonitor 1 "desc:$MONITOR_LEFT_DESC"
    hyprctl dispatch moveworkspacetomonitor 4 "desc:$MONITOR_LEFT_DESC"
    hyprctl dispatch moveworkspacetomonitor 6 "desc:$MONITOR_LEFT_DESC"

    hyprctl dispatch moveworkspacetomonitor 2 "desc:$MONITOR_RIGHT_DESC"
    hyprctl dispatch moveworkspacetomonitor 3 "desc:$MONITOR_RIGHT_DESC"
    hyprctl dispatch moveworkspacetomonitor 5 "desc:$MONITOR_RIGHT_DESC"

    # Then set defaults for future workspaces
    hyprctl keyword workspace "1,monitor:desc:$MONITOR_LEFT_DESC"
    hyprctl keyword workspace "4,monitor:desc:$MONITOR_LEFT_DESC"
    hyprctl keyword workspace "6,monitor:desc:$MONITOR_LEFT_DESC"

    hyprctl keyword workspace "2,monitor:desc:$MONITOR_RIGHT_DESC"
    hyprctl keyword workspace "3,monitor:desc:$MONITOR_RIGHT_DESC"
    hyprctl keyword workspace "5,monitor:desc:$MONITOR_RIGHT_DESC"

  else
    echo "Laptop-only setup"

    hyprctl keyword monitor "$LAPTOP,preferred,0x0,1"

    for i in {1..10}; do
      hyprctl keyword workspace "$i,monitor:$LAPTOP"
    done
  fi

  echo "Monitor setup complete"
''
