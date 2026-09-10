{ pkgs }:
let
  hyprlandTheme = import ./_hyprland-theme-adapter.nix { inherit pkgs; };
  riceSwitch = pkgs.writeShellScriptBin "rice-switch" ''
    set -euo pipefail

    jq="''${RICE_JQ:-${pkgs.jq}/bin/jq}"
    hyprland_theme="''${RICE_HYPRLAND_THEME:-${hyprlandTheme}/bin/rice-hyprland-theme}"
    quickshell="''${RICE_QUICKSHELL:-${pkgs.quickshell}/bin/quickshell}"
    wallpaper_apply="''${RICE_WALLPAPER_APPLY:-wallpaper-apply}"
    mv_command="''${RICE_MV:-${pkgs.coreutils}/bin/mv}"
    index="''${RICE_INDEX:-$HOME/.config/rice/themes.json}"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rice"
    pointer="$state_dir/active"
    wallpaper_persist="$HOME/.config/wallpaper/current"
    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(${pkgs.coreutils}/bin/id -u)}"
    lock_file="$runtime_dir/rice-switch.lock"
    pointer_tmp=""
    snapshot=""
    wallpaper_snapshot=""
    transaction_started=0
    rollback_running=0
    transaction_complete=0
    target_visual_attempted=0
    pointer_commit_attempted=0
    reload_attempted=0
    wallpaper_attempted=0
    previous_active=""
    previous_manifest=""
    previous_wallpaper=""
    pointer_existed=0
    wallpaper_existed=0
    rollback_reason="unexpected exit"

    cleanup() {
      local failed=0
      if [ -n "$pointer_tmp" ] && ! ${pkgs.coreutils}/bin/rm -f -- "$pointer_tmp"; then
        echo "rice-switch: could not remove temporary pointer $pointer_tmp" >&2
        failed=1
      fi
      if [ -n "$snapshot" ] && ! ${pkgs.coreutils}/bin/rm -f -- "$snapshot"; then
        echo "rice-switch: could not remove pointer snapshot $snapshot" >&2
        failed=1
      fi
      if [ -n "$wallpaper_snapshot" ] && ! ${pkgs.coreutils}/bin/rm -f -- "$wallpaper_snapshot"; then
        echo "rice-switch: could not remove wallpaper snapshot $wallpaper_snapshot" >&2
        failed=1
      fi
      return "$failed"
    }

    fail() {
      echo "rice-switch: $*" >&2
      exit 1
    }

    trap cleanup EXIT

    canonical_store_file() {
      local description="$1"
      local candidate="$2"
      local canonical
      canonical="$(${pkgs.coreutils}/bin/realpath -e -- "$candidate")" || fail "$description does not resolve: $candidate"
      case "$canonical" in
        /nix/store/*) ;;
        *) fail "$description must resolve to /nix/store: $candidate" ;;
      esac
      [ -f "$canonical" ] || fail "$description must resolve to a regular file: $candidate"
      printf '%s' "$canonical"
    }

    index="$(canonical_store_file "theme index" "$index")"
    "$jq" -e '
      .schemaVersion == 1 and
      (.default | type == "string" and length > 0) and
      (.themes | type == "object" and length > 0) and
      (.themes[.default] | type == "object") and
      ([.themes | to_entries[] |
        (.key | type == "string" and length > 0) and
        (.value | type == "object") and
        (.value.displayName | type == "string") and
        (.value.manifest | type == "string" and length > 0) and
        (.value.wallpapers | type == "array") and
        ([.value.wallpapers[] | type == "string"] | all)
      ] | all)
    ' "$index" >/dev/null || fail "invalid theme index at $index"

    active() {
      local selected
      selected="$("$jq" -r '.default' "$index")"
      if [ -r "$pointer" ]; then
        local pointed
        pointed="$(cat "$pointer")"
        if "$jq" -e --arg name "$pointed" '.themes[$name].manifest | type == "string"' "$index" >/dev/null; then
          selected="$pointed"
        fi
      fi
      printf %s "$selected"
    }

    manifest_for() {
      local theme_manifest
      theme_manifest="$("$jq" -er --arg name "$1" '.themes[$name].manifest | select(type == "string" and length > 0)' "$index")" || return 1
      canonical_store_file "manifest for theme '$1'" "$theme_manifest"
    }

    list() {
      local current
      current="$(active)"
      "$jq" -r '.themes | to_entries[] | "\(.key)\t\(.value.displayName)"' "$index" |
        while IFS=$'\t' read -r name display; do
          if [ "$name" = "$current" ]; then marker="*"; else marker=" "; fi
          printf '%s %-12s %s\n' "$marker" "$name" "$display"
        done
    }

    usage() {
      echo "Usage: rice-switch <theme> | --list"
      list
    }

    theme=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -h|--help)
          usage; exit 0 ;;
        -l|--list)
          list; exit 0 ;;
        --)
          shift; break ;;
        -*)
          echo "rice-switch: unknown option: $1" >&2; usage >&2; exit 64 ;;
        *)
          if [ -n "$theme" ]; then
            echo "rice-switch: expected one theme, got '$theme' and '$1'" >&2
            usage >&2
            exit 64
          fi
          theme="$1"; shift ;;
      esac
    done

    if [ -z "$theme" ]; then
      usage
      exit 0
    fi

    [ -d "$runtime_dir" ] || fail "runtime directory does not exist: $runtime_dir"
    umask 077
    [ ! -L "$lock_file" ] || fail "switch lock must not be a symlink: $lock_file"
    exec {lock_fd}>>"$lock_file" || fail "could not open switch lock: $lock_file"
    ${pkgs.util-linux}/bin/flock -n "$lock_fd" || fail "another rice-switch transaction is in progress"

    target_manifest="$(manifest_for "$theme")" || {
      echo "rice-switch: unknown theme '$theme'" >&2
      list >&2
      exit 1
    }
    "$hyprland_theme" --check --manifest "$target_manifest" --theme "$theme"

    previous_active="$(active)"
    previous_manifest="$(manifest_for "$previous_active")"
    ${pkgs.coreutils}/bin/mkdir -p -- "$state_dir" || fail "could not create state directory: $state_dir"
    if [ -e "$pointer" ] || [ -L "$pointer" ]; then
      [ -f "$pointer" ] && [ ! -L "$pointer" ] || fail "active pointer must be a regular file: $pointer"
      pointer_existed=1
      snapshot="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$state_dir" .active.snapshot.XXXXXX)" || fail "could not create pointer snapshot"
      ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$pointer" "$snapshot" || fail "could not snapshot active pointer"
    fi

    if [ -e "$wallpaper_persist" ] || [ -L "$wallpaper_persist" ]; then
      [ -f "$wallpaper_persist" ] && [ ! -L "$wallpaper_persist" ] || fail "persisted wallpaper must be a regular file: $wallpaper_persist"
      wallpaper_existed=1
      wallpaper_snapshot="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$state_dir" .wallpaper.snapshot.XXXXXX)" || fail "could not create wallpaper snapshot"
      ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$wallpaper_persist" "$wallpaper_snapshot" || fail "could not snapshot persisted wallpaper"
      previous_wallpaper="$(cat "$wallpaper_snapshot")"
    fi

    wallpaper_for() {
      local name="$1"
      local manifest="$2"
      local remembered="''${3:-}"
      local prefs="$state_dir/prefs.json"
      if [ -z "$remembered" ] && [ -r "$prefs" ]; then
        remembered="$("$jq" -r --arg name "$name" '.wallpapers[$name] // empty | select(type == "string")' "$prefs" 2>/dev/null || true)"
      fi
      local selected
      selected="$("$jq" -r --arg remembered "$remembered" '
        (.assets.wallpapers // []) as $wallpapers |
        if ($wallpapers | type) != "array" or ([ $wallpapers[] | type == "string" ] | all | not) then
          error("invalid assets.wallpapers")
        elif $remembered != "" and ($wallpapers | index($remembered)) != null then $remembered
        elif $remembered != "" then
          ($remembered | split("/") | last) as $base |
          ([ $wallpapers[] | select((split("/") | last) == $base) ][0] // $wallpapers[0] // "")
        else $wallpapers[0] // ""
        end
      ' "$manifest")" || fail "manifest for theme '$name' has invalid wallpapers"
      if [ -n "$selected" ]; then
        canonical_store_file "wallpaper for theme '$name'" "$selected"
      fi
    }

    target_wallpaper="$(wallpaper_for "$theme" "$target_manifest")"

    restore_pointer() {
      if [ "$pointer_existed" -eq 1 ]; then
        local restore_tmp
        restore_tmp="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$state_dir" .active.restore.XXXXXX)" || return 1
        if ! ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$snapshot" "$restore_tmp"; then
          ${pkgs.coreutils}/bin/rm -f -- "$restore_tmp" || true
          return 1
        fi
        if ! "$mv_command" -fT -- "$restore_tmp" "$pointer"; then
          ${pkgs.coreutils}/bin/rm -f -- "$restore_tmp" || true
          return 1
        fi
      else
        ${pkgs.coreutils}/bin/rm -f -- "$pointer"
      fi
    }

    restore_wallpaper_persistence() {
      if [ "$wallpaper_existed" -eq 1 ]; then
        local persist_dir restore_tmp
        persist_dir="$(${pkgs.coreutils}/bin/dirname -- "$wallpaper_persist")"
        ${pkgs.coreutils}/bin/mkdir -p -- "$persist_dir" || return 1
        restore_tmp="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$persist_dir" .current.restore.XXXXXX)" || return 1
        if ! ${pkgs.coreutils}/bin/cp --preserve=mode,timestamps -- "$wallpaper_snapshot" "$restore_tmp"; then
          ${pkgs.coreutils}/bin/rm -f -- "$restore_tmp" || true
          return 1
        fi
        if ! ${pkgs.coreutils}/bin/mv -fT -- "$restore_tmp" "$wallpaper_persist"; then
          ${pkgs.coreutils}/bin/rm -f -- "$restore_tmp" || true
          return 1
        fi
      else
        ${pkgs.coreutils}/bin/rm -f -- "$wallpaper_persist"
      fi
    }

    rollback() {
      local reason="$1"
      [ "$rollback_running" -eq 0 ] || return 1
      rollback_running=1
      trap - INT TERM HUP EXIT
      set +e
      local failed=0
      if [ "$target_visual_attempted" -eq 1 ] && ! "$hyprland_theme" --manifest "$previous_manifest" --theme "$previous_active"; then
        echo "rice-switch: rollback failed to restore previous Hyprland visuals; run rice-hyprland-theme --active" >&2
        failed=1
      fi
      if [ "$pointer_commit_attempted" -eq 1 ] && ! restore_pointer; then
        echo "rice-switch: rollback failed to restore the active pointer" >&2
        failed=1
      fi
      if [ "$reload_attempted" -eq 1 ] && ! "$quickshell" -c rice ipc call rice reload >/dev/null 2>&1; then
        echo "rice-switch: rollback failed to reload Quickshell" >&2
        failed=1
      fi
      if [ "$wallpaper_attempted" -eq 1 ]; then
        if [ "$wallpaper_existed" -eq 0 ]; then
          echo "rice-switch: rollback cannot restore the prior visual wallpaper because no wallpaper was previously persisted" >&2
          failed=1
        elif [ -z "$previous_wallpaper" ] || [ ! -f "$previous_wallpaper" ]; then
          echo "rice-switch: rollback cannot restore the prior visual wallpaper because its persisted path is unavailable: $previous_wallpaper" >&2
          failed=1
        elif ! "$wallpaper_apply" "$previous_wallpaper" fade 1.0; then
          echo "rice-switch: rollback failed to restore previous wallpaper" >&2
          failed=1
        fi
        if ! restore_wallpaper_persistence; then
          echo "rice-switch: rollback failed to restore wallpaper persistence" >&2
          failed=1
        fi
      fi
      if ! cleanup; then
        failed=1
      fi
      if [ "$failed" -eq 0 ]; then
        echo "rice-switch: $reason; rollback completed" >&2
      else
        echo "rice-switch: $reason; PARTIAL ROLLBACK - manual recovery required" >&2
      fi
      return 1
    }

    abort_transaction() {
      rollback_reason="$1"
      rollback "$rollback_reason" || true
      exit 1
    }

    on_signal() {
      rollback_reason="interrupted by signal $1"
      exit "$2"
    }

    on_exit() {
      local status=$?
      trap - INT TERM HUP EXIT
      if [ "$transaction_started" -eq 1 ] && [ "$transaction_complete" -eq 0 ] && [ "$rollback_running" -eq 0 ]; then
        rollback "$rollback_reason" || true
      else
        cleanup || status=1
      fi
      exit "$status"
    }

    transaction_started=1
    trap 'on_signal INT 130' INT
    trap 'on_signal TERM 143' TERM
    trap 'on_signal HUP 129' HUP
    trap on_exit EXIT

    target_visual_attempted=1
    "$hyprland_theme" --manifest "$target_manifest" --theme "$theme" ||
      abort_transaction "Hyprland rejected visual theme '$theme'"

    pointer_tmp="$(${pkgs.coreutils}/bin/mktemp --tmpdir="$state_dir" .active.new.XXXXXX)" || abort_transaction "could not create pointer staging file"
    printf %s "$theme" > "$pointer_tmp" || abort_transaction "could not stage active pointer"
    pointer_commit_attempted=1
    "$mv_command" -fT -- "$pointer_tmp" "$pointer" || abort_transaction "could not commit active pointer"
    pointer_tmp=""

    if [ "''${RICE_REQUIRE_QUICKSHELL_RELOAD:-0}" = "1" ] ||
      ${pkgs.procps}/bin/pgrep -u "''${UID:-$(${pkgs.coreutils}/bin/id -u)}" -f '[q]uickshell.*rice' >/dev/null 2>&1; then
      reload_attempted=1
      "$quickshell" -c rice ipc call rice reload >/dev/null 2>&1 ||
        abort_transaction "Quickshell reload failed"
    fi

    if [ -n "$target_wallpaper" ]; then
      wallpaper_attempted=1
      "$wallpaper_apply" "$target_wallpaper" fade 1.0 || abort_transaction "wallpaper apply failed"
    fi

    transaction_complete=1
    trap - INT TERM HUP EXIT
    cleanup || fail "theme switched but transaction cleanup failed"
    echo "rice-switch: active theme -> $theme"
  '';
in
{
  inherit hyprlandTheme riceSwitch;
}
