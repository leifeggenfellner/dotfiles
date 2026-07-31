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
  ORIGINAL_MONITOR=$(echo "$MONITORS_JSON" | $JQ -r '[.[] | select(.focused) | .name][0] // ""')
  ORIGINAL_WORKSPACE=$(echo "$MONITORS_JSON" | $JQ -r '[.[] | select(.focused) | .activeWorkspace.id][0] // ""')

  refresh_monitors() {
    MONITORS_JSON=$(hyprctl monitors -j)
  }

  has_desc() {
    echo "$MONITORS_JSON" | $JQ -e --arg d "$1" \
      '.[] | select(.description | contains($d))' >/dev/null
  }

  name_of() {
    echo "$MONITORS_JSON" | $JQ -r --arg d "$1" \
      '.[] | select(.description | contains($d)) | .name'
  }

  move_ws() {
    # Only move workspaces that actually exist
    if hyprctl workspaces -j | $JQ -e --argjson id "$1" '.[] | select(.id == $id)' >/dev/null 2>&1; then
      hyprctl dispatch moveworkspacetomonitor "$1" "$2" >/dev/null 2>&1 || true
    fi
  }

  restore_focus() {
    local ws="$1" mon="$2"
    local monitors_json

    monitors_json=$(hyprctl monitors -j)
    if [ -n "$mon" ] && echo "$monitors_json" | $JQ -e --arg m "$mon" '.[] | select(.name == $m)' >/dev/null 2>&1; then
      hyprctl dispatch focusmonitor "$mon" >/dev/null 2>&1 || true
    fi

    if [ -n "$ws" ] && hyprctl workspaces -j | $JQ -e --argjson id "$ws" '.[] | select(.id == $id)' >/dev/null 2>&1; then
      hyprctl dispatch workspace "$ws" >/dev/null 2>&1 || true
    fi
  }

  set_mon() {
    hyprctl keyword monitor "$1" >/dev/null 2>&1
  }

  set_ws() {
    hyprctl keyword workspace "$1" >/dev/null 2>&1
  }

  echo "Detected monitors:"
  echo "$MONITORS_JSON" | $JQ -r '.[].description'

  if [ -n "$MONITOR_WORK_CENTER_DESC" ] && [ -n "$MONITOR_WORK_RIGHT_DESC" ]; then
    if { has_desc "$MONITOR_WORK_CENTER_DESC" && ! has_desc "$MONITOR_WORK_RIGHT_DESC"; } || { ! has_desc "$MONITOR_WORK_CENTER_DESC" && has_desc "$MONITOR_WORK_RIGHT_DESC"; }; then
      echo "Partial work setup detected; waiting for the second work display..."
      for _ in $(seq 1 25); do
        sleep 0.2
        refresh_monitors
        if has_desc "$MONITOR_WORK_CENTER_DESC" && has_desc "$MONITOR_WORK_RIGHT_DESC"; then
          break
        fi
      done
    fi
  fi

  if [ -n "$MONITOR_HOME_DESC" ] && has_desc "$MONITOR_HOME_DESC"; then
    echo "Home setup detected"

    HOME_MON=$(name_of "$MONITOR_HOME_DESC")
    echo "Samsung output name: $HOME_MON"

    set_mon "$LAPTOP,1920x1200@60,0x0,1"
    set_mon "$HOME_MON,3440x1440@60,1920x0,1"

    # Bind workspaces to monitors first — affects both existing and new workspaces
    set_ws "1,monitor:$HOME_MON,default:true"
    set_ws "2,monitor:$HOME_MON"
    set_ws "3,monitor:$LAPTOP,default:true"
    set_ws "4,monitor:$LAPTOP"
    set_ws "5,monitor:$LAPTOP"
    set_ws "6,monitor:$LAPTOP"

    move_ws 1 "$HOME_MON"
    move_ws 2 "$HOME_MON"
    for i in {3..6}; do
      move_ws "$i" "$LAPTOP"
    done

  elif [ -n "$MONITOR_WORK_CENTER_DESC" ] && [ -n "$MONITOR_WORK_RIGHT_DESC" ] && has_desc "$MONITOR_WORK_CENTER_DESC" && has_desc "$MONITOR_WORK_RIGHT_DESC"; then
    echo "Work setup detected"

    CENTER_MON=$(name_of "$MONITOR_WORK_CENTER_DESC")
    RIGHT_MON=$(name_of "$MONITOR_WORK_RIGHT_DESC")
    echo "Center monitor: $CENTER_MON, Right monitor: $RIGHT_MON"

    set_mon "$LAPTOP,1920x1200@60,0x0,1"
    set_mon "$CENTER_MON,2560x1440@60,1920x0,1"
    set_mon "$RIGHT_MON,2560x1440@60,4480x0,1"

    # Bind workspaces to monitors first
    set_ws "1,monitor:$CENTER_MON,default:true"
    set_ws "6,monitor:$CENTER_MON"
    set_ws "3,monitor:$RIGHT_MON,default:true"
    set_ws "7,monitor:$RIGHT_MON"
    set_ws "2,monitor:$LAPTOP,default:true"
    set_ws "4,monitor:$LAPTOP"
    set_ws "5,monitor:$LAPTOP"

    move_ws 1 "$CENTER_MON"
    move_ws 6 "$CENTER_MON"
    move_ws 3 "$RIGHT_MON"
    move_ws 7 "$RIGHT_MON"
    move_ws 2 "$LAPTOP"
    move_ws 4 "$LAPTOP"
    move_ws 5 "$LAPTOP"

  elif [ -n "$MONITOR_WORK_CENTER_DESC" ] && [ -n "$MONITOR_WORK_RIGHT_DESC" ] && { has_desc "$MONITOR_WORK_CENTER_DESC" || has_desc "$MONITOR_WORK_RIGHT_DESC"; }; then
    echo "Partial work setup detected"

    set_mon "$LAPTOP,1920x1200@60,0x0,1"

    if has_desc "$MONITOR_WORK_CENTER_DESC"; then
      CENTER_MON=$(name_of "$MONITOR_WORK_CENTER_DESC")
      echo "Center monitor: $CENTER_MON"

      set_mon "$CENTER_MON,2560x1440@60,1920x0,1"

      set_ws "1,monitor:$CENTER_MON,default:true"
      set_ws "6,monitor:$CENTER_MON"
      set_ws "2,monitor:$LAPTOP,default:true"
      set_ws "3,monitor:$LAPTOP"
      set_ws "4,monitor:$LAPTOP"
      set_ws "5,monitor:$LAPTOP"
      set_ws "7,monitor:$LAPTOP"

      move_ws 1 "$CENTER_MON"
      move_ws 6 "$CENTER_MON"
      for i in 2 3 4 5 7; do
        move_ws "$i" "$LAPTOP"
      done
    else
      RIGHT_MON=$(name_of "$MONITOR_WORK_RIGHT_DESC")
      echo "Right monitor: $RIGHT_MON"

      set_mon "$RIGHT_MON,2560x1440@60,1920x0,1"

      set_ws "3,monitor:$RIGHT_MON,default:true"
      set_ws "7,monitor:$RIGHT_MON"
      set_ws "1,monitor:$LAPTOP,default:true"
      set_ws "2,monitor:$LAPTOP"
      set_ws "4,monitor:$LAPTOP"
      set_ws "5,monitor:$LAPTOP"
      set_ws "6,monitor:$LAPTOP"

      move_ws 3 "$RIGHT_MON"
      move_ws 7 "$RIGHT_MON"
      for i in 1 2 4 5 6; do
        move_ws "$i" "$LAPTOP"
      done
    fi

  else
    echo "Laptop-only setup"

    set_mon "$LAPTOP,preferred,0x0,1"

    for i in {1..10}; do
      set_ws "$i,monitor:$LAPTOP"
    done
  fi

  # Wake any DPMS-sleeping monitors
  hyprctl dispatch dpms on 2>/dev/null || true
  restore_focus "$ORIGINAL_WORKSPACE" "$ORIGINAL_MONITOR"

  echo "Monitor setup complete"
''
