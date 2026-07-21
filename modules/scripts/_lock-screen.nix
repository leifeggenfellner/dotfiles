{ pkgs, lib, monitorPriority ? [ ], accentPrimary ? "mauve", opacityLockscreen ? 0.8, ... }:

# lock-screen — templates a dynamic hyprlock config at lock time:
#   1. monitor selection (priority walk over connected monitors)
#   2. background: active rice theme's lockscreen asset → live
#      wallpaper persist file → baked default (D-020)
#   3. rice theming: $rice_* variable lines re-pointed at the ACTIVE
#      theme's manifest colors/fonts (pointer → index → manifest,
#      read-only — same resolution order as rice-switch)
# The variable spec is shared with the HM hyprlock config
# (modules/programs/_hyprlock-vars.nix) so mapping lives once.
# `--print-config` writes and prints the config without locking.
#
# NOTE: HM's toHyprconf emits `key=value` (no spaces) — all patterns
# below are whitespace-tolerant EREs anchored on the key.

let
  vars = import ../programs/_hyprlock-vars.nix {
    inherit accentPrimary opacityLockscreen;
  };
  # 0.8 → "cc": alpha as 2-digit hex for hyprlang rgba(RRGGBBAA).
  alphaHex = a: lib.toLower (lib.fixedWidthString 2 "0"
    (lib.toHexString (builtins.floor (a * 255.0 + 0.5))));
  colorTable = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (n: v: "${n} ${v.key} ${alphaHex v.alpha}") vars.colors);
  fontTable = lib.concatStringsSep "\n"
    (lib.mapAttrsToList (n: v: "${n} ${v.family}") vars.fonts);
in
pkgs.writeShellScriptBin "lock-screen" ''
    set -euo pipefail

    JQ=${pkgs.jq}/bin/jq
    SED=${pkgs.gnused}/bin/sed
    HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
    DYNAMIC_CONF="''${TMPDIR:-/tmp}/hyprlock-dynamic.conf"
    MODE="''${1:-}"

    # Phase 7: `--fast` opts out of the veil handoff. Suspend-driven
    # locks pass it via hypridle's before_sleep_cmd — there is no
    # point animating 280 ms of fog when DPMS is about to blank the
    # screen. The flag is stripped from rice-lock-screen's argv since
    # rice-lock-screen doesn't recognise it.
    _fast=0
    _rice_args=()
    for _arg in "$@"; do
      case "$_arg" in
        --fast) _fast=1 ;;
        *) _rice_args+=("$_arg") ;;
      esac
    done

    lock_active() {
      pgrep -x hyprlock >/dev/null 2>&1 || pgrep -f '[q]uickshell.*lock[.]qml' >/dev/null 2>&1
    }

    if [ "$MODE" != "--print-config" ] && [ "$MODE" != "--dry-run" ] && lock_active; then
      exit 0
    fi

    if [ "$_fast" = "1" ] && command -v rice-lock-screen >/dev/null 2>&1; then
      exec rice-lock-screen "''${_rice_args[@]}"
    fi

    if [ "$MODE" != "--print-config" ] && [ "$MODE" != "--dry-run" ] && command -v rice-lock-screen >/dev/null 2>&1; then
      # Phase 6: prefer veil-then-lock handoff when the rice shell is
      # reachable. IPC to ambient.lockWithVeil is fire-and-forget; the
      # shell schedules the veil fade and spawns rice-lock-screen. If
      # rice isn't up we fall through to direct exec (no veil).
      _variant=""
      _prev=""
      for _arg in "$@"; do
        case "$_arg" in
          --variant=*) _variant="''${_arg#--variant=}" ;;
        esac
        if [ "$_prev" = "--variant" ]; then
          _variant="$_arg"
        fi
        _prev="$_arg"
      done
      if command -v quickshell >/dev/null 2>&1 \
        && ${pkgs.coreutils}/bin/timeout 0.5 quickshell -c rice ipc call ambient status >/dev/null 2>&1; then
        quickshell -c rice ipc call ambient lockWithVeil "$_variant" >/dev/null 2>&1 || true
        exit 0
      fi
      exec rice-lock-screen "$@"
    fi

    # Ordered monitor descriptors to prefer for the lock UI (injected from Nix)
    PRIORITY=(${builtins.concatStringsSep " " (map (d: ''"${d}"'') monitorPriority)})

    MONITORS_JSON=$(hyprctl monitors -j 2>/dev/null || echo '[]')

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

    # Copy config, replacing non-empty monitor values with the target.
    # The background's empty `monitor=` is untouched (`.+` needs a value).
    if [ -n "$TARGET" ]; then
      $SED -E "s|^(\s*monitor\s*=).+|\1$TARGET|" "$HYPRLOCK_CONF" > "$DYNAMIC_CONF"
    else
      cp "$HYPRLOCK_CONF" "$DYNAMIC_CONF"
    fi

    # ── Active rice theme (D-020): pointer → index → manifest ──
    INDEX="$HOME/.config/rice/themes.json"
    POINTER="''${XDG_STATE_HOME:-$HOME/.local/state}/rice/active"
    MANIFEST=""
    if [ -r "$INDEX" ]; then
      NAME=""
      [ -r "$POINTER" ] && NAME=$(cat "$POINTER")
      if [ -z "$NAME" ] || ! $JQ -e --arg n "$NAME" '.themes[$n]' "$INDEX" >/dev/null 2>&1; then
        NAME=$($JQ -r '.default // empty' "$INDEX")
      fi
      [ -n "$NAME" ] && MANIFEST=$($JQ -r --arg n "$NAME" '.themes[$n].manifest // empty' "$INDEX")
      [ -r "$MANIFEST" ] || MANIFEST=""
    fi

    # Background precedence: theme lockscreen asset → live wallpaper → baked.
    LIVE_WP=""
    if [ -n "$MANIFEST" ]; then
      LIVE_WP=$($JQ -r '.assets.lockscreen[0] // empty' "$MANIFEST")
    fi
    if [ -z "$LIVE_WP" ] || [ ! -f "$LIVE_WP" ]; then
      PERSIST_WP="$HOME/.config/wallpaper/current"
      [ -f "$PERSIST_WP" ] && LIVE_WP=$(cat "$PERSIST_WP") || LIVE_WP=""
    fi
    if [ -n "$LIVE_WP" ] && [ -f "$LIVE_WP" ]; then
      $SED -i -E "s|^(\s*path\s*=).+|\1$LIVE_WP|" "$DYNAMIC_CONF"
    fi

    # Re-point $rice_* definitions at the active theme. Per-key skip on
    # missing/malformed values — the baked defaults stand. Quoted
    # heredocs: tables are Nix-interpolated data, not shell-expanded.
    if [ -n "$MANIFEST" ]; then
      while read -r var key alpha; do
        hex=$($JQ -r --arg k "$key" '.palette.legacy[$k] // empty' "$MANIFEST")
        [[ "$hex" =~ ^[0-9a-fA-F]{6}$ ]] || continue
        $SED -i -E "s|^\s*[\$]$var\s*=.+|\$$var=rgba($hex$alpha)|" "$DYNAMIC_CONF"
      done <<'COLORS'
  ${colorTable}
  COLORS
      while read -r var fam; do
        val=$($JQ -r --arg f "$fam" '.tokens.typography.families[$f] // empty' "$MANIFEST")
        [ -n "$val" ] || continue
        val="''${val//&/\\&}"   # sed replacement escape; '|' in a family would still break
        $SED -i -E "s|^\s*[\$]$var\s*=.+|\$$var=$val|" "$DYNAMIC_CONF"
      done <<'FONTS'
  ${fontTable}
  FONTS
    fi

    if [ "$MODE" = "--print-config" ] || [ "$MODE" = "--dry-run" ]; then
      cat "$DYNAMIC_CONF"
      exit 0
    fi

    exec hyprlock --config "$DYNAMIC_CONF"
''
