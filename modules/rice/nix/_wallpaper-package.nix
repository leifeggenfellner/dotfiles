{ pkgs, awww ? "${pkgs.awww}/bin/awww" }:
pkgs.writeShellScriptBin "wallpaper-apply" ''
  set -euo pipefail

  WP="''${1:-}"
  TRANSITION="''${2:-fade}"
  DURATION="''${3:-1.0}"
  PERSIST_FILE="$HOME/.config/wallpaper/current"
  PERSIST_TMP=""

  cleanup() {
    [ -z "$PERSIST_TMP" ] || ${pkgs.coreutils}/bin/rm -f -- "$PERSIST_TMP"
  }
  trap cleanup EXIT

  if [ -z "$WP" ] || [ ! -f "$WP" ]; then
    echo "wallpaper-apply: missing readable wallpaper: $WP" >&2
    exit 64
  fi

  ${awww}-daemon 2>/dev/null &
  disown || true
  for _ in $(seq 1 50); do
    ${awww} query >/dev/null 2>&1 && break
    sleep 0.1
  done

  outputs=$(${awww} query 2>/dev/null | ${pkgs.gnused}/bin/sed -n 's/^: \([^:]*\):.*/\1/p' | ${pkgs.coreutils}/bin/paste -sd, -)
  if [ -n "$outputs" ]; then
    ${awww} img "$WP" \
      --outputs "$outputs" \
      --transition-type "$TRANSITION" \
      --transition-duration "$DURATION" \
      --transition-fps 60 2>/dev/null
  else
    ${awww} img "$WP" \
      --transition-type "$TRANSITION" \
      --transition-duration "$DURATION" \
      --transition-fps 60 2>/dev/null
  fi

  mkdir -p "$(dirname "$PERSIST_FILE")"
  PERSIST_TMP=$(${pkgs.coreutils}/bin/mktemp --tmpdir="$(dirname "$PERSIST_FILE")" .current.XXXXXX)
  printf '%s\n' "$WP" > "$PERSIST_TMP"
  ${pkgs.coreutils}/bin/mv -fT -- "$PERSIST_TMP" "$PERSIST_FILE"
  PERSIST_TMP=""
''
