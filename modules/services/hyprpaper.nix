_: {
  flake.homeModules.services-hyprpaper =
    { lib, pkgs, osConfig, ... }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
      awww = "${pkgs.awww}/bin/awww";

      # Boot-time wallpaper restore script: reads persisted path, falls back to Nix default
      wallpaper-restore = pkgs.writeShellScriptBin "wallpaper-restore" ''
        set -euo pipefail
        PERSIST_FILE="$HOME/.config/wallpaper/current"
        DEFAULT="${wallpaper}"

        # Start daemon if not running
        ${awww}-daemon 2>/dev/null &
        disown
        # Give daemon a moment to initialise
        sleep 0.3

        # Use persisted wallpaper if it exists and points to a real file
        WP="$DEFAULT"
        if [ -f "$PERSIST_FILE" ]; then
          SAVED=$(cat "$PERSIST_FILE")
          if [ -f "$SAVED" ]; then
            WP="$SAVED"
          fi
        fi

        # Seed the persist file if missing
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
