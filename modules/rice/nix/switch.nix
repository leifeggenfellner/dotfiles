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

      rice-switch = pkgs.writeShellScriptBin "rice-switch" ''
        set -euo pipefail

        jq=${pkgs.jq}/bin/jq
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

        case "''${1:-}" in
          ""|-h|--help)
            echo "Usage: rice-switch <theme> | --list"; list; exit 0 ;;
          -l|--list)
            list; exit 0 ;;
        esac

        theme="$1"
        "$jq" -e --arg n "$theme" '.themes[$n]' "$index" >/dev/null || {
          echo "rice-switch: unknown theme '$theme'" >&2; list >&2; exit 1
        }

        # Atomic pointer write: the shell watches this file (live re-bind).
        mkdir -p "$state_dir"
        printf %s "$theme" > "$pointer.tmp" && mv "$pointer.tmp" "$pointer"

        # Wallpaper orchestration: first theme wallpaper, same awww flow
        # and persist file as WallpaperState / wallpaper-restore. Themes
        # without wallpapers keep the current one.
        wp="$("$jq" -r --arg n "$theme" '.themes[$n].wallpapers[0] // empty' "$index")"
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
