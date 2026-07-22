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

  # Ensure a workspace exists on the target monitor — create it if missing
  ensure_ws() {
    local ws="$1" mon="$2"
    if ! hyprctl workspaces -j | $JQ -e --argjson id "$ws" '.[] | select(.id == $id)' >/dev/null 2>&1; then
      # Focus the target monitor first, then create workspace there
      hyprctl dispatch focusmonitor "$mon" >/dev/null 2>&1 || true
      hyprctl dispatch workspace "$ws" >/dev/null 2>&1 || true
    fi
  }

  # Clean up auto-created empty workspaces (11, 12, etc.) on newly added monitors
  cleanup_empty() {
    hyprctl workspaces -j | $JQ -r '.[] | select(.id >= 10 and .windows == 0) | .id' 2>/dev/null | while read -r ws; do
      # Switch away from it, then it'll be cleaned up if empty
      hyprctl dispatch workspace 1 >/dev/null 2>&1 || true
    done
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

    # Ensure target workspaces exist, then move them
    ensure_ws 1 "$HOME_MON"
    ensure_ws 2 "$HOME_MON"
    for i in {3..6}; do
      ensure_ws "$i" "$LAPTOP"
    done

    move_ws 1 "$HOME_MON"
    move_ws 2 "$HOME_MON"
    for i in {3..6}; do
      move_ws "$i" "$LAPTOP"
    done

    cleanup_empty

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

    # Ensure target workspaces exist, then move them
    ensure_ws 1 "$CENTER_MON"
    ensure_ws 6 "$CENTER_MON"
    ensure_ws 3 "$RIGHT_MON"
    ensure_ws 7 "$RIGHT_MON"
    ensure_ws 2 "$LAPTOP"
    ensure_ws 4 "$LAPTOP"
    ensure_ws 5 "$LAPTOP"

    move_ws 1 "$CENTER_MON"
    move_ws 6 "$CENTER_MON"
    move_ws 3 "$RIGHT_MON"
    move_ws 7 "$RIGHT_MON"
    move_ws 2 "$LAPTOP"
    move_ws 4 "$LAPTOP"
    move_ws 5 "$LAPTOP"

    cleanup_empty

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

      ensure_ws 1 "$CENTER_MON"
      ensure_ws 6 "$CENTER_MON"
      for i in 2 3 4 5 7; do
        ensure_ws "$i" "$LAPTOP"
      done

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

      ensure_ws 3 "$RIGHT_MON"
      ensure_ws 7 "$RIGHT_MON"
      for i in 1 2 4 5 6; do
        ensure_ws "$i" "$LAPTOP"
      done

      move_ws 3 "$RIGHT_MON"
      move_ws 7 "$RIGHT_MON"
      for i in 1 2 4 5 6; do
        move_ws "$i" "$LAPTOP"
      done
    fi

    cleanup_empty

  else
    echo "Laptop-only setup"

    set_mon "$LAPTOP,preferred,0x0,1"

    for i in {1..10}; do
      set_ws "$i,monitor:$LAPTOP"
    done
  fi

  # Wake any DPMS-sleeping monitors
  hyprctl dispatch dpms on 2>/dev/null || true

  echo "Monitor setup complete"
''
