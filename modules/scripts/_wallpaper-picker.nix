{ pkgs, wallpaperDir, ... }:
let
  awww = "${pkgs.awww}/bin/awww";
  chafa = "${pkgs.chafa}/bin/chafa";
  fzf = "${pkgs.fzf}/bin/fzf";
  notify = "${pkgs.libnotify}/bin/notify-send";
  find = "${pkgs.findutils}/bin/find";
  file = "${pkgs.file}/bin/file";

  # Standalone preview script that fzf can call
  previewScript = pkgs.writeShellScript "wp-preview" ''
    img="$1"
    CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
    mkdir -p "$CACHE_DIR"
    hash=$(echo "$img" | md5sum | cut -d' ' -f1)
    thumb="$CACHE_DIR/$hash.txt"
    if [ ! -f "$thumb" ]; then
      ${chafa} --size=60x20 --animate=off "$img" > "$thumb" 2>/dev/null || echo "(no preview)" > "$thumb"
    fi
    cat "$thumb"
    echo ""
    echo "  $(basename "$img")"
    dims=$(${file} "$img" 2>/dev/null | grep -oP '\d+ x \d+' | head -1)
    if [ -n "''${dims:-}" ]; then
      echo "  ''${dims}"
    fi
  '';

  # Standalone live-preview script for awww
  liveScript = pkgs.writeShellScript "wp-live" ''
    ${awww} img "$1" \
      --transition-type fade \
      --transition-duration 0.8 \
      --transition-fps 60 \
      --transition-bezier ".42,0,.58,1" 2>/dev/null || true
  '';
in
pkgs.writeShellScriptBin "wallpaper-picker" ''
  set -euo pipefail

  WALLPAPER_DIR="${wallpaperDir}"
  PERSIST_FILE="$HOME/.config/wallpaper/current"
  CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
  ORIGINAL=""

  mkdir -p "$(dirname "$PERSIST_FILE")" "$CACHE_DIR"

  # ── Restore original wallpaper on cancel ──────────────────────────
  cleanup() {
    if [ -n "$ORIGINAL" ] && [ -f "$PERSIST_FILE" ]; then
      current=$(cat "$PERSIST_FILE")
      if [ "$current" != "$ORIGINAL" ]; then
        echo "$ORIGINAL" > "$PERSIST_FILE"
        ${awww} img "$ORIGINAL" \
          --transition-type fade \
          --transition-duration 0.5 \
          --transition-fps 60 2>/dev/null || true
      fi
    fi
  }

  # Save current wallpaper so we can revert
  if [ -f "$PERSIST_FILE" ]; then
    ORIGINAL=$(cat "$PERSIST_FILE")
  fi

  # ── Find all wallpapers ──────────────────────────────────────────
  IMAGES=$(${find} "$WALLPAPER_DIR" -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \
       -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
    | sort)

  if [ -z "$IMAGES" ]; then
    ${notify} "Wallpaper Picker" "No images found in $WALLPAPER_DIR" -t 3000
    exit 1
  fi

  # Mark the current wallpaper in the list
  CURRENT=""
  if [ -f "$PERSIST_FILE" ]; then
    CURRENT=$(cat "$PERSIST_FILE")
  fi

  # ── Launch fzf picker ─────────────────────────────────────────────
  trap cleanup EXIT

  SELECTED=$(echo "$IMAGES" | ${fzf} \
    --preview '${previewScript} {}' \
    --preview-window='right:50%:wrap' \
    --bind "focus:execute-silent(${liveScript} {})" \
    --header="  Wallpaper Picker  ─  Current: $(basename "''${CURRENT:-none}")" \
    --header-first \
    --prompt="▸ " \
    --pointer="●" \
    --cycle \
    --no-info \
    --reverse \
    --border=rounded \
    --margin=1,2 \
    --padding=1 \
    --color="fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8,fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8,info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc,marker:#a6e3a1,spinner:#f5e0dc,header:#94e2d5,border:#6c7086" \
  ) || true

  # Remove the trap — we don't want cleanup if user confirmed
  trap - EXIT

  if [ -z "''${SELECTED:-}" ]; then
    # User cancelled — revert
    if [ -n "$ORIGINAL" ]; then
      ${awww} img "$ORIGINAL" \
        --transition-type fade \
        --transition-duration 0.5 \
        --transition-fps 60 2>/dev/null || true
    fi
    exit 0
  fi

  # ── Apply and persist ─────────────────────────────────────────────
  echo "$SELECTED" > "$PERSIST_FILE"

  # Final set with a nicer transition
  ${awww} img "$SELECTED" \
    --transition-type grow \
    --transition-duration 1.2 \
    --transition-fps 60 \
    --transition-pos center 2>/dev/null || true

  ${notify} "Wallpaper" "Set: $(basename "$SELECTED")" -t 3000
''
