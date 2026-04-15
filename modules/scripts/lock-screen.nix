{ pkgs, ... }:

pkgs.writeShellScriptBin "lock-screen" ''
  set -euo pipefail

  JQ=${pkgs.jq}/bin/jq
  AWK=${pkgs.gawk}/bin/awk
  HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
  DYNAMIC_CONF="/tmp/hyprlock-dynamic.conf"

  WORK_DESC="HP Inc. HP 527pu 1H35421YT0"
  HOME_DESC="Samsung Electric Company C34J79x HTRM900265"
  LAPTOP_DESC="LG Display 0x0791"

  MONITORS_JSON=$(hyprctl monitors -j)

  has_desc() {
    echo "$MONITORS_JSON" | $JQ -e --arg d "$1" \
      '.[] | select(.description | contains($d))' >/dev/null 2>&1
  }

  # Determine which monitor to show the lock UI on
  if has_desc "$WORK_DESC"; then
    REMOVE1="$HOME_DESC"
    REMOVE2="$LAPTOP_DESC"
  elif has_desc "$HOME_DESC"; then
    REMOVE1="$WORK_DESC"
    REMOVE2="$LAPTOP_DESC"
  else
    REMOVE1="$WORK_DESC"
    REMOVE2="$HOME_DESC"
  fi

  # Remove entire { } blocks that reference non-target monitors
  $AWK -v r1="$REMOVE1" -v r2="$REMOVE2" '
    /\{/ { block = ""; depth++ }
    { block = block $0 "\n" }
    /\}/ {
      depth--
      if (depth == 0) {
        if (block !~ r1 && block !~ r2) printf "%s", block
        block = ""
      }
    }
    depth == 0 && !/\{/ && !/\}/ { printf "%s\n", $0 }
  ' "$HYPRLOCK_CONF" > "$DYNAMIC_CONF"

  exec hyprlock --config "$DYNAMIC_CONF"
''
