{ pkgs, themes, ... }:
let
  themesStr = builtins.concatStringsSep "\\n" themes;
  wofi = "${pkgs.wofi}/bin/wofi";
  notify = "${pkgs.libnotify}/bin/notify-send";
  swaync-client = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  jq = "${pkgs.jq}/bin/jq";
in
pkgs.writeShellScriptBin "theme-switcher" ''
  set -euo pipefail

  DOTFILES="$HOME/Sources/dotfiles"
  THEME_FILE="$DOTFILES/modules/themes/_active-scheme.nix"
  VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"

  # Map scheme names to VS Code theme names
  declare -A VSCODE_THEMES=(
    ["catppuccin-mocha"]="Catppuccin Mocha"
    ["catppuccin-macchiato"]="Catppuccin Macchiato"
    ["catppuccin-frappe"]="Catppuccin Frappé"
    ["catppuccin-latte"]="Catppuccin Latte"
    ["nord"]="Nord"
    ["tokyo-night"]="Tokyo Night"
    ["rose-pine"]="Rosé Pine"
    ["gruvbox-dark"]="Gruvbox Dark Medium"
    ["dracula"]="Dracula"
  )

  # Show theme picker
  SELECTED=$(echo -e "${themesStr}" | ${wofi} --dmenu --prompt "Select Theme" --width 400 --height 300) || true

  # Exit if nothing selected
  if [ -z "''${SELECTED:-}" ]; then
    exit 0
  fi

  ${notify} "Theme Switcher" "Applying: $SELECTED" -t 3000

  # Write the selection to active-scheme file for next rebuild
  echo "\"$SELECTED\"" > "$THEME_FILE"

  # Immediately update VS Code theme (replace symlink with mutable copy)
  VSCODE_THEME="''${VSCODE_THEMES[$SELECTED]:-Catppuccin Mocha}"
  if [ -e "$VSCODE_SETTINGS" ]; then
    REAL_SETTINGS=$(realpath "$VSCODE_SETTINGS")
    TEMP_FILE=$(mktemp)
    # Modify in a temp file first— only apply if jq succeeds and output is non-empty
    if ${jq} --arg theme "$VSCODE_THEME" \
      '."workbench.colorTheme" = $theme | ."workbench.preferredDarkColorTheme" = $theme' \
      "$REAL_SETTINGS" > "$TEMP_FILE" 2>/dev/null && [ -s "$TEMP_FILE" ]; then
      rm -f "$VSCODE_SETTINGS"
      mv "$TEMP_FILE" "$VSCODE_SETTINGS"
    else
      rm -f "$TEMP_FILE"
    fi
  fi

  # Hot-reload swaync CSS
  ${swaync-client} --reload-css 2>/dev/null || true

  # Hot-reload waybar
  pkill -SIGUSR2 waybar 2>/dev/null || true

  ${notify} "Theme Switcher" "Rebuilding system in background..." -t 5000

  # Trigger full rebuild in background for complete theme application
  sudo nixos-rebuild switch --flake "$DOTFILES" &>/tmp/theme-rebuild.log &
''
