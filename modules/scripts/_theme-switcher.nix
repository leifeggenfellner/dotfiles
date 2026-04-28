{ pkgs, lib, themes, palettes, currentScheme, ... }:
let
  fzf = "${pkgs.fzf}/bin/fzf";
  notify = "${pkgs.libnotify}/bin/notify-send";
  swaync-client = "${pkgs.swaynotificationcenter}/bin/swaync-client";
  jq = "${pkgs.jq}/bin/jq";

  # Ordered display keys
  displayKeys = [
    "mauve"
    "blue"
    "sapphire"
    "teal"
    "green"
    "yellow"
    "peach"
    "red"
    "pink"
    "flamingo"
    "rosewater"
    "lavender"
    "sky"
    "maroon"
    "text"
    "subtext1"
    "overlay1"
    "surface1"
    "surface0"
    "base"
    "mantle"
    "crust"
  ];

  # Terminal color indices (ANSI 0-15)
  termKeys = [
    "base"
    "red"
    "green"
    "yellow"
    "blue"
    "mauve"
    "teal"
    "text"
    "surface1"
    "red"
    "green"
    "yellow"
    "blue"
    "mauve"
    "teal"
    "text"
  ];

  # ── Baked case-statement generators ────────────────────────────────
  # All color data is baked into scripts at Nix eval time as case branches,
  # so fzf subprocesses don't need env var propagation.

  paletteCaseBranches = builtins.concatStringsSep "\n    " (
    lib.mapAttrsToList
      (name: palette:
        let hexes = builtins.concatStringsSep " " (map (k: palette.${k}) displayKeys);
        in "${name}) echo \"${hexes}\" ;;"
      )
      palettes
  );

  borderCaseBranches = builtins.concatStringsSep "\n    " (
    lib.mapAttrsToList
      (name: palette:
        "${name}) echo \"${palette.mauve} ${palette.blue} ${palette.sapphire} ${palette.surface0}\" ;;"
      )
      palettes
  );

  termCaseBranches = builtins.concatStringsSep "\n    " (
    lib.mapAttrsToList
      (name: palette:
        let ansi = builtins.concatStringsSep " " (map (k: palette.${k}) termKeys);
        in "${name}) echo \"${ansi} ${palette.text} ${palette.base} ${palette.rosewater}\" ;;"
      )
      palettes
  );

  vscodeCaseBranches = builtins.concatStringsSep "\n    " (map
    (t:
      let
        vsName = {
          "catppuccin-mocha" = "Catppuccin Mocha";
          "catppuccin-macchiato" = "Catppuccin Macchiato";
          "catppuccin-frappe" = "Catppuccin Frappé";
          "catppuccin-latte" = "Catppuccin Latte";
          "nord" = "Nord";
          "tokyo-night" = "Tokyo Night";
          "rose-pine" = "Rosé Pine";
          "gruvbox-dark" = "Gruvbox Dark Medium";
          "dracula" = "Dracula";
        }.${t} or t;
      in
      "${t}) echo \"${vsName}\" ;;"
    )
    themes);

  # ── Preview script (fzf --preview) ────────────────────────────────
  previewScript = pkgs.writeShellScript "theme-preview" ''
    line="$1"
    scheme=$(echo "$line" | sed 's/^\*\? *//; s/ (current)$//')

    get_palette() {
      case "$1" in
        ${paletteCaseBranches}
        *) echo "" ;;
      esac
    }

    IFS=' ' read -ra colors <<< "$(get_palette "$scheme")"
    if [ ''${#colors[@]} -eq 0 ]; then
      echo "Unknown theme: $scheme"
      exit 0
    fi

    hex_to_rgb() {
      printf '%d %d %d' "0x''${1:0:2}" "0x''${1:2:2}" "0x''${1:4:2}"
    }
    color_block() {
      local r g b
      read -r r g b <<< "$(hex_to_rgb "$1")"
      printf '\033[48;2;%d;%d;%dm    \033[0m' "$r" "$g" "$b"
    }
    label_block() {
      local r g b
      read -r r g b <<< "$(hex_to_rgb "$2")"
      printf '\033[38;2;%d;%d;%dm%-12s\033[0m' "$r" "$g" "$b" "$1"
    }

    names=(mauve blue sapphire teal green yellow peach red pink flamingo rosewater lavender sky maroon text subtext1 overlay1 surface1 surface0 base mantle crust)

    echo ""
    echo "  Accents"
    echo "  -------"
    for i in $(seq 0 7); do
      printf '  '; color_block "''${colors[$i]}"; printf ' '
      label_block "''${names[$i]}" "''${colors[$i]}"; echo ""
    done

    echo ""
    echo "  Spectrum"
    echo "  --------"
    for i in $(seq 8 13); do
      printf '  '; color_block "''${colors[$i]}"; printf ' '
      label_block "''${names[$i]}" "''${colors[$i]}"; echo ""
    done

    echo ""
    echo "  Surfaces"
    echo "  --------"
    for i in $(seq 14 21); do
      if [ $i -lt ''${#colors[@]} ]; then
        printf '  '; color_block "''${colors[$i]}"; printf ' '
        label_block "''${names[$i]}" "''${colors[$i]}"; echo ""
      fi
    done

    echo ""
    printf '  '
    for c in "''${colors[@]}"; do color_block "$c"; done
    echo ""
  '';

  # ── Live preview script (fzf focus:execute-silent) ────────────────
  # Only updates hyprland borders — fast, no blocking, no env vars needed
  livePreviewScript = pkgs.writeShellScript "theme-live-preview" ''
    line="$1"
    scheme=$(echo "$line" | sed 's/^\*\? *//; s/ (current)$//')

    get_borders() {
      case "$1" in
        ${borderCaseBranches}
        *) echo "" ;;
      esac
    }

    IFS=' ' read -r accent1 accent2 accent3 inactive <<< "$(get_borders "$scheme")"
    [ -z "$accent1" ] && exit 0

    hyprctl keyword general:col.active_border "rgb($accent1) rgb($accent2) rgb($accent3) 45deg" >/dev/null 2>&1 || true
    hyprctl keyword general:col.inactive_border "rgb($inactive)" >/dev/null 2>&1 || true
    hyprctl keyword group:col.border_active "rgb($accent1)" >/dev/null 2>&1 || true
    hyprctl keyword group:col.border_inactive "rgb($inactive)" >/dev/null 2>&1 || true
  '';

  # ── Terminal color apply script (called on final apply only) ──────
  termApplyScript = pkgs.writeShellScript "theme-term-apply" ''
    scheme="$1"
    tty_target="$2"

    get_term_colors() {
      case "$1" in
        ${termCaseBranches}
        *) echo "" ;;
      esac
    }

    IFS=' ' read -ra tc <<< "$(get_term_colors "$scheme")"
    [ ''${#tc[@]} -eq 0 ] && exit 0

    {
      for i in $(seq 0 15); do
        hex="''${tc[$i]}"
        printf '\033]4;%d;rgb:%s/%s/%s\033\\' "$i" "''${hex:0:2}" "''${hex:2:2}" "''${hex:4:2}"
      done
      fg="''${tc[16]}"; printf '\033]10;rgb:%s/%s/%s\033\\' "''${fg:0:2}" "''${fg:2:2}" "''${fg:4:2}"
      bg="''${tc[17]}"; printf '\033]11;rgb:%s/%s/%s\033\\' "''${bg:0:2}" "''${bg:2:2}" "''${bg:4:2}"
      cur="''${tc[18]}"; printf '\033]12;rgb:%s/%s/%s\033\\' "''${cur:0:2}" "''${cur:2:2}" "''${cur:4:2}"
    } > "$tty_target" 2>/dev/null || true
  '';

in
pkgs.writeShellScriptBin "theme-switcher" ''
  set -euo pipefail

  DOTFILES="$HOME/Sources/dotfiles"
  THEME_FILE="$DOTFILES/modules/themes/_active-scheme.nix"
  RUNTIME_THEME="$HOME/.config/theme-current"
  VSCODE_SETTINGS="$HOME/.config/Code/User/settings.json"

  # Read current scheme from the Nix source file at runtime
  if [ -f "$THEME_FILE" ]; then
    CURRENT_SCHEME=$(tr -d '"' < "$THEME_FILE" | tr -d '[:space:]')
  else
    CURRENT_SCHEME="${currentScheme}"
  fi
  ORIGINAL_SCHEME="$CURRENT_SCHEME"

  MY_TTY=$(tty 2>/dev/null || echo "")

  # Apply terminal colors to all user-owned pts devices
  apply_term_all() {
    local scheme="$1"
    for pts in /dev/pts/[0-9]*; do
      [ -w "$pts" ] && ${termApplyScript} "$scheme" "$pts"
    done
  }

  get_vscode_theme() {
    case "$1" in
      ${vscodeCaseBranches}
      *) echo "Catppuccin Mocha" ;;
    esac
  }

  THEMES=(${builtins.concatStringsSep " " (map (t: "\"${t}\"") themes)})

  # ── Build fzf input: mark current theme ───────────────────────────
  INPUT=""
  for theme in "''${THEMES[@]}"; do
    if [ "$theme" = "$CURRENT_SCHEME" ]; then
      INPUT+="* $theme (current)"$'\n'
    else
      INPUT+="  $theme"$'\n'
    fi
  done

  # ── Cleanup: restore on cancel ────────────────────────────────────
  cleanup() {
    ${livePreviewScript} "  $ORIGINAL_SCHEME"
    if [ -n "$MY_TTY" ]; then
      ${termApplyScript} "$ORIGINAL_SCHEME" "$MY_TTY"
    fi
  }
  trap cleanup EXIT

  # ── Launch fzf ────────────────────────────────────────────────────
  SELECTED=$(echo -n "$INPUT" | ${fzf} \
    --preview '${previewScript} {}' \
    --preview-window='right:40%:wrap' \
    --bind "focus:execute-silent(${livePreviewScript} {})" \
    --header="Theme Switcher  |  current: $CURRENT_SCHEME" \
    --header-first \
    --prompt="theme > " \
    --pointer=">" \
    --no-info \
    --reverse \
    --cycle \
    --border=rounded \
    --margin=1,2 \
    --padding=1 \
  ) || true

  trap - EXIT

  # Parse selection
  PICKED=$(echo "''${SELECTED:-}" | sed 's/^\*\? *//; s/ (current)$//')

  if [ -z "$PICKED" ]; then
    ${livePreviewScript} "  $ORIGINAL_SCHEME"
    if [ -n "$MY_TTY" ]; then
      ${termApplyScript} "$ORIGINAL_SCHEME" "$MY_TTY"
    fi
    exit 0
  fi

  if [ "$PICKED" = "$ORIGINAL_SCHEME" ]; then
    exit 0
  fi

  # ── Apply permanently ─────────────────────────────────────────────
  echo "\"$PICKED\"" > "$THEME_FILE"
  echo "$PICKED" > "$RUNTIME_THEME"

  ${livePreviewScript} "  $PICKED"

  apply_term_all "$PICKED"

  # Cache OSC sequences so new terminals pick up the theme immediately
  mkdir -p "$HOME/.cache"
  ${termApplyScript} "$PICKED" "$HOME/.cache/theme-term-colors"

  ${swaync-client} --reload-css 2>/dev/null || true
  pkill -SIGUSR2 waybar 2>/dev/null || true

  vscode_theme=$(get_vscode_theme "$PICKED")
  if [ -e "$VSCODE_SETTINGS" ]; then
    real_settings=$(realpath "$VSCODE_SETTINGS")
    temp_file=$(mktemp)
    if ${jq} --arg theme "$vscode_theme" \
      '."workbench.colorTheme" = $theme | ."workbench.preferredDarkColorTheme" = $theme' \
      "$real_settings" > "$temp_file" 2>/dev/null && [ -s "$temp_file" ]; then
      rm -f "$VSCODE_SETTINGS"
      mv "$temp_file" "$VSCODE_SETTINGS"
    else
      rm -f "$temp_file"
    fi
  fi

  ${notify} "Theme Switcher" "Applied: $PICKED -- rebuilding..." -t 5000
  sudo nixos-rebuild switch --flake "$DOTFILES" &>/tmp/theme-rebuild.log &
''
