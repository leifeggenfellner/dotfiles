{ pkgs, monitorPriority ? [ ], ... }:

pkgs.writeShellScriptBin "lock-screen" ''
  set -euo pipefail

  JQ=${pkgs.jq}/bin/jq
  SED=${pkgs.gnused}/bin/sed
  HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
  DYNAMIC_CONF="/tmp/hyprlock-dynamic.conf"

  # Ordered monitor descriptors to prefer for the lock UI (injected from Nix)
  PRIORITY=(${builtins.concatStringsSep " " (map (d: ''"${d}"'') monitorPriority)})

  MONITORS_JSON=$(hyprctl monitors -j)

  has_desc() {
    echo "$MONITORS_JSON" | $JQ -e --arg d "$1" \
      '.[] | select(.description | contains($d))' >/dev/null 2>&1
  }

  # Walk priority list, pick the first connected monitor
  TARGET=""
  for desc in "''${PRIORITY[@]}"; do
    if has_desc "$desc"; then
      TARGET="desc:$desc"
      break
    fi
  done

  # Fallback: use the focused monitor
  if [ -z "$TARGET" ]; then
    TARGET=$(echo "$MONITORS_JSON" | $JQ -r '.[] | select(.focused) | .name')
  fi

  # Copy config, replacing non-empty monitor values with the target
  # Background uses 'monitor =' (empty) and is left untouched
  $SED -E "s|(monitor = ).+|\1$TARGET|" \
    "$HYPRLOCK_CONF" > "$DYNAMIC_CONF"

  exec hyprlock --config "$DYNAMIC_CONF"
''
