# rice-switch — layer 2 of the theme switch (D-003, D-018): mutates
# the $XDG_STATE_HOME/rice/active pointer against the Nix-built
# themes.json index. Layer 1 (building all themes + index) lives in
# manifest.nix/_index-lib.nix. The shell re-binds live by watching
# the pointer; the IPC nudge only covers the pointer-file-created
# case, which file watching can miss.
_: {
  flake.homeModules.rice-switch =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      specialisationsEnabled = if (cfg.specialisations.enable or false) then "1" else "0";
      specialisationPrefix = cfg.specialisations.prefix or "rice-";

      rice-switch = pkgs.writeShellScriptBin "rice-switch" ''
        set -euo pipefail

        jq=${pkgs.jq}/bin/jq
        specialisations_enabled=${specialisationsEnabled}
        specialisation_prefix=${lib.escapeShellArg specialisationPrefix}
        index="$HOME/.config/rice/themes.json"
        state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rice"
        pointer="$state_dir/active"

        [ -r "$index" ] || { echo "rice-switch: no theme index at $index (rebuild with rice.enable)" >&2; exit 1; }

        active() {
          if [ -r "$pointer" ]; then cat "$pointer"; else "$jq" -r '.default' "$index"; fi
        }

        list() {
          local cur; cur="$(active)"
          "$jq" -r '.themes | to_entries[] | "\(.key)\t\(.value.displayName)"' "$index" |
            while IFS=$'\t' read -r name display; do
              if [ "$name" = "$cur" ]; then marker="*"; else marker=" "; fi
              printf '%s %-12s %s\n' "$marker" "$name" "$display"
            done
        }

        usage() {
          echo "Usage: rice-switch [--specialise] <theme> | --list"
          list
        }

        specialise=0
        theme=""
        while [ "$#" -gt 0 ]; do
          case "$1" in
            -h|--help)
              usage; exit 0 ;;
            -l|--list)
              list; exit 0 ;;
            --specialise|--specialize|--system)
              specialise=1; shift ;;
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

        "$jq" -e --arg n "$theme" '.themes[$n]' "$index" >/dev/null || {
          echo "rice-switch: unknown theme '$theme'" >&2; list >&2; exit 1
        }

        if [ "$specialise" -eq 1 ]; then
          [ "$specialisations_enabled" = "1" ] || {
            echo "rice-switch: rice specialisations are disabled in this generation" >&2
            exit 69
          }
          spec="$specialisation_prefix$theme"
          switcher="/run/current-system/specialisation/$spec/bin/switch-to-configuration"
          [ -x "$switcher" ] || {
            echo "rice-switch: no generated specialisation '$spec' in /run/current-system" >&2
            exit 69
          }
          if [ "''${EUID:-$(id -u)}" -eq 0 ]; then
            "$switcher" switch
          else
            sudo "$switcher" switch
          fi
        fi

        # Atomic pointer write: the shell watches this file (live re-bind).
        mkdir -p "$state_dir"
        printf %s "$theme" > "$pointer.tmp" && mv "$pointer.tmp" "$pointer"

        # Wallpaper orchestration (D-019): the theme's remembered
        # last-used wallpaper (prefs.json — written only by PrefsState;
        # read-only here), else its first wallpaper from the index. A
        # remembered path gone stale (rebuilt store hash) is re-matched
        # by basename before falling back. Themes without wallpapers
        # keep the current one. Same awww flow and persist file as
        # WallpaperState / wallpaper-restore.
        prefs="$state_dir/prefs.json"
        wp=""
        if [ -r "$prefs" ]; then
          wp="$("$jq" -r --arg n "$theme" '.wallpapers[$n] // empty' "$prefs" 2>/dev/null || true)"
        fi
        if [ -n "$wp" ] && [ ! -r "$wp" ]; then
          wp="$("$jq" -r --arg n "$theme" --arg b "$(basename "$wp")" \
            '.themes[$n].wallpapers[] | select(endswith("/" + $b))' "$index" | head -n1)"
        fi
        if [ -z "$wp" ] || [ ! -r "$wp" ]; then
          wp="$("$jq" -r --arg n "$theme" '.themes[$n].wallpapers[0] // empty' "$index")"
        fi
        if [ -n "$wp" ] && [ -r "$wp" ] && command -v awww >/dev/null; then
          awww img "$wp" --transition-type fade --transition-duration 1.0 --transition-fps 60 &&
            mkdir -p "$HOME/.config/wallpaper" &&
            printf %s "$wp" > "$HOME/.config/wallpaper/current" || true
        fi

        # Nudge a running shell in case the pointer file was just created
        # (a watch set on a missing file does not always fire on creation).
        quickshell -c rice ipc call rice reload >/dev/null 2>&1 || true

        echo "rice-switch: active theme → $theme"
      '';
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [ rice-switch ];
      };
    };
}
