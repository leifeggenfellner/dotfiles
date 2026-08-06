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

  lua_quote() {
    printf '%s' "$1" | $JQ -Rsa .
  }

  hypr_eval() {
    hyprctl eval "$1" >/dev/null 2>&1
  }

  hypr_dispatch() {
    hypr_eval "hl.dispatch($1)"
  }

  move_ws() {
    local workspace="$1" monitor="$2"

    # Only move workspaces that actually exist
    if hyprctl workspaces -j | $JQ -e --argjson id "$workspace" '.[] | select(.id == $id)' >/dev/null 2>&1; then
      hypr_dispatch "hl.dsp.workspace.move({ workspace = $(lua_quote "$workspace"), monitor = $(lua_quote "$monitor") })" || true
    fi
  }

  restore_focus() {
    local ws="$1" mon="$2"
    local monitors_json

    monitors_json=$(hyprctl monitors -j)
    if [ -n "$mon" ] && echo "$monitors_json" | $JQ -e --arg m "$mon" '.[] | select(.name == $m)' >/dev/null 2>&1; then
      hypr_dispatch "hl.dsp.focus({ monitor = $(lua_quote "$mon") })" || true
    fi

    if [ -n "$ws" ] && hyprctl workspaces -j | $JQ -e --argjson id "$ws" '.[] | select(.id == $id)' >/dev/null 2>&1; then
      hypr_dispatch "hl.dsp.focus({ workspace = $(lua_quote "$ws") })" || true
    fi
  }

  set_mon() {
    local output mode position scale lua_scale

    IFS=',' read -r output mode position scale <<< "$1"
    if [ "$mode" = "disable" ]; then
      hypr_eval "hl.monitor({ output = $(lua_quote "$output"), disabled = true })"
      return
    fi

    if [ -z "$scale" ] || printf '%s\n' "$scale" | grep -q '[^0-9.]'; then
      lua_scale="\"$scale\""
    else
      lua_scale="$scale"
    fi

    hypr_eval "hl.monitor({ output = $(lua_quote "$output"), mode = $(lua_quote "$mode"), position = $(lua_quote "$position"), scale = $lua_scale })"
  }

  set_ws() {
    local spec="$1" workspace rest part monitor is_default lua

    IFS=',' read -r workspace rest <<< "$spec"
    monitor=""
    is_default="false"

    IFS=',' read -ra parts <<< "$rest"
    for part in "''${parts[@]}"; do
      case "$part" in
        monitor:*) monitor="''${part#monitor:}" ;;
        default:true) is_default="true" ;;
      esac
    done

    lua="{ workspace = $(lua_quote "$workspace")"
    if [ -n "$monitor" ]; then
      lua="$lua, monitor = $(lua_quote "$monitor")"
    fi
    if [ "$is_default" = "true" ]; then
      lua="$lua, default = true"
    fi
    lua="$lua }"

    hypr_eval "hl.workspace_rule($lua)"
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
  hypr_dispatch 'hl.dsp.dpms({ action = "on" })' || true
  restore_focus "$ORIGINAL_WORKSPACE" "$ORIGINAL_MONITOR"

  echo "Monitor setup complete"
''

