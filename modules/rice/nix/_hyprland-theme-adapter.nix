{ pkgs }:
let
  inherit (pkgs) lib;
  activeManifestLib = import ./_active-manifest-lib.nix { inherit pkgs; };

  # Leaves a theme's compositor motion may override (D-047), and the
  # baseline leaf each one inherits from in the generated config.
  baseline = import ../../programs/hyprland/_animations.nix;
  overridable = {
    windowsIn = "windowsIn";
    windowsOut = "windowsOut";
    windowsMove = "windowsMove";
    fadeIn = "fade";
    fadeOut = "fade";
    workspaces = "workspaces";
    layersIn = "layersIn";
    layersOut = "layersOut";
  };
  baselineFor = source:
    lib.findFirst (a: a.leaf == source) (throw "baseline animation '${source}' missing") baseline.animation;
  # Re-applied before every theme's overrides, so switching to a theme
  # without compositor motion restores the generated config's values.
  baselineLua = lib.concatStrings (lib.mapAttrsToList
    (leaf: source:
      let a = baselineFor source; in
      "hl.animation({ leaf = ${builtins.toJSON leaf}, enabled = ${lib.boolToString a.enabled}, speed = ${toString a.speed}, bezier = ${builtins.toJSON a.bezier}"
      + lib.optionalString (a ? style) ", style = ${builtins.toJSON a.style}"
      + " })\n")
    overridable);

  # Themes without `integration.cursor` get the base style's cursor
  # (what the generated config shows before any rice theme, D-048).
  baseStyle = import ../../themes/_style.nix;
in
pkgs.writeShellScriptBin "rice-hyprland-theme" ''
  set -euo pipefail

  jq="''${RICE_JQ:-${pkgs.jq}/bin/jq}"
  hyprctl="''${RICE_HYPRCTL:-${pkgs.hyprland}/bin/hyprctl}"
  index="''${RICE_INDEX:-$HOME/.config/rice/themes.json}"
  state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rice"
  pointer="$state_dir/active"
  prefs="$state_dir/prefs.json"
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

  # Reduce-motion is a user pref (D-022); unreadable prefs mean "off".
  # RICE_REDUCE_MOTION=1|0 overrides it (the shell passes the new value
  # when the pref changes, before prefs.json is necessarily written).
  reduce=false
  if [ -n "''${RICE_REDUCE_MOTION:-}" ]; then
    [ "$RICE_REDUCE_MOTION" = 1 ] && reduce=true
  elif [ -r "$prefs" ]; then
    reduce="$("$jq" -r '.motion.reduce == true' "$prefs" 2>/dev/null || echo false)"
  fi

  # The closed mapping (D-039, amended by D-047): border colours, the
  # global animation switch, and optional compositor motion whose
  # speeds and curves derive from the theme's motion tokens. Emitted as
  # one Lua chunk for `hyprctl eval` (Hyprland's Lua config has no
  # `keyword` request).
  lua="$("$jq" -er --arg expected "$expected_theme" --argjson reduce "$reduce" '
    def color: type == "string" and test("^#[0-9a-fA-F]{6}$");
    def ms: type == "number" and floor == . and . > 0 and . <= 10000;
    def style($p): type == "string" and test("^" + $p + "$");
    def speed: (. / 10 | round) / 10;
    # Qt easing name → cubic bezier (Elastic/Bounce have none; they get
    # their Back neighbour). Unknown names follow the runtime: OutCubic.
    def bezier: {
      "Linear": [0, 0, 1, 1],
      "InQuad": [0.11, 0, 0.5, 0], "OutQuad": [0.5, 1, 0.89, 1], "InOutQuad": [0.45, 0, 0.55, 1],
      "InCubic": [0.32, 0, 0.67, 0], "OutCubic": [0.33, 1, 0.68, 1], "InOutCubic": [0.65, 0, 0.35, 1],
      "InQuart": [0.5, 0, 0.75, 0], "OutQuart": [0.25, 1, 0.5, 1], "InOutQuart": [0.76, 0, 0.24, 1],
      "InQuint": [0.64, 0, 0.78, 0], "OutQuint": [0.22, 1, 0.36, 1], "InOutQuint": [0.83, 0, 0.17, 1],
      "InExpo": [0.7, 0, 0.84, 0], "OutExpo": [0.16, 1, 0.3, 1], "InOutExpo": [0.87, 0, 0.13, 1],
      "InSine": [0.12, 0, 0.39, 0], "OutSine": [0.61, 1, 0.88, 1], "InOutSine": [0.37, 0, 0.63, 1],
      "InBack": [0.36, 0, 0.66, -0.56], "OutBack": [0.34, 1.56, 0.64, 1], "InOutBack": [0.68, -0.6, 0.32, 1.6],
      "InElastic": [0.36, 0, 0.66, -0.56], "OutElastic": [0.34, 1.56, 0.64, 1],
      "InBounce": [0.36, 0, 0.66, -0.56], "OutBounce": [0.34, 1.56, 0.64, 1]
    }[.] // [0.33, 1, 0.68, 1];
    def curve($name): "hl.curve(\"rice_\($name)\", { type = \"bezier\", points = { {\(.[0]), \(.[1])}, {\(.[2]), \(.[3])} } })\n";
    def anim($leaf; $ms; $curve; $style):
      "hl.animation({ leaf = \"\($leaf)\", enabled = true, speed = \($ms | speed), bezier = \"rice_\($curve)\""
      + (if $style == null then "" else ", style = \"\($style)\"" end) + " })\n";

    select(
      .meta.schemaVersion == 2 and
      (.meta.name | type == "string") and
      ($expected == "" or .meta.name == $expected) and
      (.tokens.colors.accent.primary | color) and
      (.tokens.colors.bg.elevated | color) and
      (.tokens.motion.enabled | type == "boolean") and
      ([.tokens.motion.durations | .fast, .base, .slow] | all(ms)) and
      ([.tokens.motion.easings | .standard, .enter, .exit] | all(type == "string")) and
      ((.tokens.motion.compositor // {}) as $c |
        ($c | type == "object") and
        ($c | keys - ["windowsIn", "windowsOut", "workspaces", "layers"] | length == 0) and
        ([$c.windowsIn, $c.windowsOut] | all(. == null or style("(slide|gnomed|popin( [0-9]{1,2}%)?)"))) and
        ($c.workspaces | . == null or style("(slide|slidevert|fade|slidefade( [0-9]{1,2}%)?|slidefadevert( [0-9]{1,2}%)?)")) and
        ($c.layers | . == null or style("(slide|fade|popin( [0-9]{1,2}%)?)")))
    ) |
    (.tokens.colors.accent.primary | ltrimstr("#")) as $active |
    (.tokens.colors.bg.elevated | ltrimstr("#")) as $inactive |
    (.tokens.motion.enabled and ($reduce | not)) as $animate |
    .tokens.motion as $m |
    "hl.config({ general = { col = { active_border = \"rgb(\($active))\", inactive_border = \"rgb(\($inactive))\" } }, "
    + "group = { col = { border_active = \"rgb(\($active))\", border_inactive = \"rgb(\($inactive))\" } }, "
    + "animations = { enabled = \($animate) } })\n"
    + (if $animate then
        $baseline
        + (if $m.compositor == null then "" else
            ($m.easings.standard | bezier | curve("standard"))
            + ($m.easings.enter | bezier | curve("enter"))
            + ($m.easings.exit | bezier | curve("exit"))
            + anim("windowsIn"; $m.durations.slow; "enter"; $m.compositor.windowsIn)
            + anim("windowsOut"; $m.durations.base; "exit"; $m.compositor.windowsOut)
            + anim("windowsMove"; $m.durations.base; "standard"; null)
            + anim("fadeIn"; $m.durations.slow; "enter"; null)
            + anim("fadeOut"; $m.durations.fast; "exit"; null)
            + anim("workspaces"; $m.durations.base; "standard"; $m.compositor.workspaces)
            + anim("layersIn"; $m.durations.base; "enter"; $m.compositor.layers)
            + anim("layersOut"; $m.durations.fast; "exit"; $m.compositor.layers)
          end)
      else "" end)
  ' --arg baseline ${lib.escapeShellArg baselineLua} "$manifest")" || fail "manifest does not provide valid normalized Hyprland visual tokens: $manifest"

  # Cursor (D-048): the theme's, or the base style's. setcursor reports
  # "ok" even for a theme it cannot find, so a theme cursor must be
  # installed (any icon dir on the XDG path) before anything is applied.
  cursor="$("$jq" -er '
    (.integration.cursor // null) as $c |
    if $c == null then "${baseStyle.cursor_name} ${toString baseStyle.cursor_size}"
    elif ($c.name | type == "string" and test("^[A-Za-z0-9._-]+$")) and ($c.size | type == "number" and floor == . and . >= 8 and . <= 128)
    then "\($c.name) \($c.size)"
    else error("invalid integration.cursor") end
  ' "$manifest")" || fail "manifest has an invalid integration.cursor: $manifest"
  cursor_name="''${cursor% *}"
  if [ "$cursor_name" != ${lib.escapeShellArg baseStyle.cursor_name} ]; then
    found=0
    IFS=: read -ra data_dirs <<< "''${XDG_DATA_HOME:-$HOME/.local/share}:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
    for icons in "$HOME/.icons" "''${data_dirs[@]/%//icons}"; do
      if [ -e "$icons/$cursor_name/manifest.hl" ] || [ -d "$icons/$cursor_name/cursors" ]; then
        found=1; break
      fi
    done
    [ "$found" -eq 1 ] || fail "cursor theme '$cursor_name' is not installed in any icon directory"
  fi

  [ "$check_only" -eq 0 ] || exit 0

  # eval exits non-zero and prints the Lua error on failure.
  if ! out="$("$hyprctl" eval "$lua" 2>&1)"; then
    fail "Hyprland rejected the theme: $out"
  fi
  # shellcheck disable=SC2086 # "<name> <size>", both validated above
  if ! out="$("$hyprctl" setcursor $cursor 2>&1)"; then
    fail "Hyprland rejected the cursor: $out"
  fi
''
