{ pkgs }:
let
  activeManifestLib = import ./_active-manifest-lib.nix { inherit pkgs; };
in
pkgs.writeShellScriptBin "rice-hyprland-theme" ''
  set -euo pipefail

  jq="''${RICE_JQ:-${pkgs.jq}/bin/jq}"
  hyprctl="''${RICE_HYPRCTL:-${pkgs.hyprland}/bin/hyprctl}"
  index="''${RICE_INDEX:-$HOME/.config/rice/themes.json}"
  state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rice"
  pointer="$state_dir/active"
  check_only=0
  manifest=""
  expected_theme=""

  fail() {
    echo "rice-hyprland-theme: $*" >&2
    exit 1
  }

  ${activeManifestLib}

  usage() {
    echo "Usage: rice-hyprland-theme [--check] (--active | --manifest <path> [--theme <name>])"
  }

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --check)
        check_only=1; shift ;;
      --active)
        [ -z "$manifest" ] || fail "choose exactly one manifest source"
        rice_resolve_active
        expected_theme="$active_theme"
        shift ;;
      --manifest)
        [ "$#" -ge 2 ] || fail "--manifest requires a path"
        [ -z "$manifest" ] || fail "choose exactly one manifest source"
        manifest="$2"; shift 2 ;;
      --theme)
        [ "$#" -ge 2 ] || fail "--theme requires a name"
        expected_theme="$2"; shift 2 ;;
      -h|--help)
        usage; exit 0 ;;
      *)
        fail "unknown argument: $1" ;;
    esac
  done

  [ -n "$manifest" ] || { usage >&2; exit 64; }
  manifest="$(canonical_store_file "theme manifest" "$manifest")"

  values="$("$jq" -er --arg expected "$expected_theme" '
    def color: type == "string" and test("^#[0-9a-fA-F]{6}$");
    def metric: type == "number" and floor == . and . >= 0 and . <= 512;
    select(
      .meta.schemaVersion == 2 and
      (.meta.name | type == "string") and
      ($expected == "" or .meta.name == $expected) and
      (.tokens.colors.accent.primary | color) and
      (.tokens.colors.bg.surface1 | color) and
      (.tokens.metrics.radius.medium | metric) and
      (.tokens.metrics.space.sm | metric) and
      (.tokens.metrics.space.md | metric)
    ) |
    [
      (.tokens.colors.accent.primary | ltrimstr("#")),
      (.tokens.colors.bg.surface1 | ltrimstr("#")),
      .tokens.metrics.radius.medium,
      .tokens.metrics.space.sm,
      .tokens.metrics.space.md
    ] | @tsv
  ' "$manifest")" || fail "manifest does not provide valid normalized Hyprland visual tokens: $manifest"

  [ "$check_only" -eq 0 ] || exit 0

  IFS=$'\t' read -r active_border inactive_border rounding gaps_in gaps_out <<< "$values"
  "$hyprctl" --batch "keyword general:col.active_border rgb($active_border); keyword general:col.inactive_border rgb($inactive_border); keyword group:col.border_active rgb($active_border); keyword group:col.border_inactive rgb($inactive_border); keyword decoration:rounding $rounding; keyword general:gaps_in $gaps_in; keyword general:gaps_out $gaps_out"
''
