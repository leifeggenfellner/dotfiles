_: {
  flake.homeModules.services-hyprpaper =
    { lib, pkgs, osConfig, ... }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
      awww = "${pkgs.awww}/bin/awww";

      # Boot-time wallpaper restore: persisted path, with rice-aware
      # recovery when it went stale (store paths in the persist file
      # die on rebuild+GC — the assets hash changes whenever any theme
      # asset does; nh clean collects the old one). Recovery mirrors
      # rice-switch (D-019): basename re-match against the ACTIVE
      # theme's current wallpaper list, else the theme's remembered
      # prefs entry, else its first wallpaper, else the Nix default.
      wallpaper-restore = pkgs.writeShellScriptBin "wallpaper-restore" ''
        set -euo pipefail
        JQ=${pkgs.jq}/bin/jq
        PERSIST_FILE="$HOME/.config/wallpaper/current"
        DEFAULT="${wallpaper}"

        # Start daemon if not running, then wait until it answers
        # (a fixed grace period races a cold multi-monitor boot).
        ${awww}-daemon 2>/dev/null &
        disown
        for _ in $(seq 1 50); do
          ${awww} query >/dev/null 2>&1 && break
          sleep 0.1
        done

        SAVED=""
        if [ -f "$PERSIST_FILE" ]; then
          SAVED=$(cat "$PERSIST_FILE")
        fi

        WP=""
        if [ -n "$SAVED" ] && [ -f "$SAVED" ]; then
          WP="$SAVED"
        else
          # Persisted path is gone — recover through the rice state
          # (skipped gracefully on non-rice hosts: no index, no jq run).
          INDEX="$HOME/.config/rice/themes.json"
          POINTER="''${XDG_STATE_HOME:-$HOME/.local/state}/rice/active"
          PREFS="''${XDG_STATE_HOME:-$HOME/.local/state}/rice/prefs.json"
          if [ -r "$INDEX" ]; then
            NAME=""
            [ -r "$POINTER" ] && NAME=$(cat "$POINTER")
            if [ -z "$NAME" ] || ! $JQ -e --arg n "$NAME" '.themes[$n]' "$INDEX" >/dev/null 2>&1; then
              NAME=$($JQ -r '.default // empty' "$INDEX")
            fi
            if [ -n "$NAME" ]; then
              if [ -n "$SAVED" ]; then
                WP=$($JQ -r --arg n "$NAME" --arg b "$(basename "$SAVED")" \
                  '.themes[$n].wallpapers[] | select(endswith("/" + $b))' "$INDEX" | head -n1)
              fi
              if { [ -z "$WP" ] || [ ! -f "$WP" ]; } && [ -r "$PREFS" ]; then
                WP=$($JQ -r --arg n "$NAME" '.wallpapers[$n] // empty' "$PREFS")
              fi
              if [ -z "$WP" ] || [ ! -f "$WP" ]; then
                WP=$($JQ -r --arg n "$NAME" '.themes[$n].wallpapers[0] // empty' "$INDEX")
              fi
            fi
          fi
        fi
        if [ -z "$WP" ] || [ ! -f "$WP" ]; then
          WP="$DEFAULT"
        fi

        # Re-seed the persist file with the resolved (live) path
        mkdir -p "$(dirname "$PERSIST_FILE")"
        echo "$WP" > "$PERSIST_FILE"

        ${awww} img "$WP" \
          --transition-type fade \
          --transition-duration 1.0 \
          --transition-fps 60 2>/dev/null || true
      '';
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home.packages = [
          pkgs.awww
          wallpaper-restore
        ];
      };
    };
}
