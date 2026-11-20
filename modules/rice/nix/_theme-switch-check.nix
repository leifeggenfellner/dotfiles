{ pkgs }:
let
  packages = import ./_switch-package.nix { inherit pkgs; };
  cyberWallpaper = pkgs.writeText "cyber-wallpaper.png" "cyber";
  fixtureMotion = {
    enabled = true;
    durations = { fast = 160; base = 280; slow = 400; };
    easings = { standard = "OutCubic"; enter = "OutQuint"; exit = "InCubic"; };
  };
  lotmWallpaper = pkgs.writeText "lotm-wallpaper.png" "lotm";
  cyberManifest = pkgs.writeText "cyberpunk-manifest.json" (builtins.toJSON {
    meta = { name = "cyberpunk"; schemaVersion = 2; };
    tokens = { colors = { accent.primary = "#00e5ff"; bg.elevated = "#141b2b"; }; motion = fixtureMotion; };
    assets.wallpapers = [ cyberWallpaper ];
  });
  lotmManifest = pkgs.writeText "lotm-manifest.json" (builtins.toJSON {
    meta = { name = "lotm"; schemaVersion = 2; };
    tokens = {
      colors = { accent.primary = "#c79a3a"; bg.elevated = "#2a211a"; bg.sunken = "#0e0a06"; state.warn = "#d9a441"; };
      typography.families.display = "Cinzel";
      motion = fixtureMotion // { compositor = { windowsIn = "popin 85%"; windowsOut = "popin 90%"; workspaces = "slidefadevert 12%"; layers = "fade"; borderSweep = "once"; borderFade = "off"; }; };
      chrome = {
        border = { active = [ "state.warn" "accent.primary" ]; inactive = [ "bg.elevated" "bg.sunken" ]; angle = 45; width = 3; };
        rounding = 0;
        shadow = { color = "bg.sunken"; range = 18; power = 2; offset = [ 3 5 ]; };
        groupbar = { active = [ "accent.primary" ]; text = "bg.sunken"; font = "display"; };
      };
    };
    widgets = {
      tarotDraw.settings.cards = [{ id = "fool"; } { id = "moon"; accent = "#dd7a6e"; }];
      dailyAccent.settings = { record = "extras.tarotDraw.daily"; catalog = "widgets.tarotDraw.settings.cards"; };
    };
    integration.cursor = { name = "fixture-quill"; size = 24; };
    assets.wallpapers = [ lotmWallpaper ];
  });
  invalidManifest = pkgs.writeText "invalid-manifest.json" ''{"meta":{"name":"invalid","schemaVersion":2}}'';
  index = pkgs.writeText "rice-themes.json" (builtins.toJSON {
    schemaVersion = 1;
    default = "cyberpunk";
    themes = {
      cyberpunk = { displayName = "Cyberpunk"; manifest = cyberManifest; wallpapers = [ cyberWallpaper ]; };
      lotm = { displayName = "LOTM"; manifest = lotmManifest; wallpapers = [ lotmWallpaper ]; };
      invalid = { displayName = "Invalid"; manifest = invalidManifest; wallpapers = [ ]; };
    };
  });
  malformedIndex = pkgs.writeText "malformed-rice-themes.json" ''{"schemaVersion":1,"default":"missing","themes":{}}'';
  mutableManifestIndex = pkgs.writeText "mutable-manifest-rice-themes.json" (builtins.toJSON {
    schemaVersion = 1;
    default = "mutable";
    themes.mutable = { displayName = "Mutable"; manifest = "/build/rice-switch-mutable-manifest.json"; wallpapers = [ ]; };
  });
  hyprctlMock = pkgs.writeShellScript "rice-hyprctl-mock" ''
    echo "hypr $*" >> "$RICE_TEST_LOG"
    if [ -n "''${RICE_BLOCK_HYPR_MATCH:-}" ] && [[ "$*" == *"$RICE_BLOCK_HYPR_MATCH"* ]]; then
      touch "$RICE_BLOCK_ENTERED"
      while [ ! -e "$RICE_BLOCK_RELEASE" ]; do ${pkgs.coreutils}/bin/sleep 0.01; done
    fi
    if [ -n "''${RICE_FAIL_HYPR_MATCH:-}" ] && [[ "$*" == *"$RICE_FAIL_HYPR_MATCH"* ]]; then
      exit 42
    fi
    if [ -n "''${RICE_FAIL_ROLLBACK_HYPR_MATCH:-}" ] && [[ "$*" == *"$RICE_FAIL_ROLLBACK_HYPR_MATCH"* ]]; then
      exit 43
    fi
  '';
  quickshellMock = pkgs.writeShellScript "rice-quickshell-mock" ''
    echo "reload" >> "$RICE_TEST_LOG"
    count=0
    [ ! -f "$RICE_RELOAD_COUNT" ] || count=$(cat "$RICE_RELOAD_COUNT")
    count=$((count + 1))
    printf %s "$count" > "$RICE_RELOAD_COUNT"
    if [ "''${RICE_SIGNAL_RELOAD:-0}" = 1 ] && [ "$count" = 1 ]; then
      kill -TERM "$PPID"
      exit 143
    fi
    [ "$count" != "''${RICE_FAIL_RELOAD_AT:-0}" ]
  '';
  awwwMock = pkgs.runCommand "rice-awww-mock" { } ''
    mkdir -p "$out/bin"
    cp ${pkgs.writeShellScript "awww" ''
      echo "awww $*" >> "$RICE_TEST_LOG"
      case "''${1:-}" in
        query) printf ': DP-1: 1920x1080\n' ;;
        img)
          if [ -n "''${RICE_FAIL_WALLPAPER_MATCH:-}" ] && [[ "''${2:-}" == *"$RICE_FAIL_WALLPAPER_MATCH"* ]]; then
            exit 44
          fi
          ;;
      esac
    ''} "$out/bin/awww"
    cp ${pkgs.writeShellScript "awww-daemon" ''
      echo "awww-daemon" >> "$RICE_TEST_LOG"
    ''} "$out/bin/awww-daemon"
  '';
  wallpaperApply = import ./_wallpaper-package.nix { inherit pkgs; awww = "${awwwMock}/bin/awww"; };
  mvMock = pkgs.writeShellScript "rice-mv-mock" ''
    count=0
    [ ! -f "$RICE_MV_COUNT" ] || count=$(cat "$RICE_MV_COUNT")
    count=$((count + 1))
    printf %s "$count" > "$RICE_MV_COUNT"
    if [ "$count" = "''${RICE_FAIL_MV_AT:-0}" ]; then
      [ "''${RICE_FAIL_MV_AFTER:-0}" != 1 ] || ${pkgs.coreutils}/bin/mv "$@"
      exit 45
    fi
    ${pkgs.coreutils}/bin/mv "$@"
  '';
in
pkgs.runCommand "rice-theme-switch"
{
  nativeBuildInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.jq pkgs.shellcheck ];
}
  ''
    shellcheck -e SC2016 ${packages.hyprlandTheme}/bin/rice-hyprland-theme
    shellcheck -e SC2016 ${packages.riceSwitch}/bin/rice-switch
    shellcheck -e SC2016 ${wallpaperApply}/bin/wallpaper-apply

    export HOME="$TMPDIR/home"
    export XDG_STATE_HOME="$TMPDIR/state"
    export XDG_RUNTIME_DIR="$TMPDIR/runtime"
    export RICE_INDEX=${index}
    export RICE_HYPRCTL=${hyprctlMock}
    export RICE_HYPRLAND_THEME=${packages.hyprlandTheme}/bin/rice-hyprland-theme
    export RICE_QUICKSHELL=${quickshellMock}
    export RICE_WALLPAPER_APPLY=${wallpaperApply}/bin/wallpaper-apply
    export RICE_MV=${mvMock}
    export RICE_REQUIRE_QUICKSHELL_RELOAD=1
    export RICE_TEST_LOG="$TMPDIR/effects.log"
    export RICE_RELOAD_COUNT="$TMPDIR/reload.count"
    export RICE_MV_COUNT="$TMPDIR/mv.count"
    export XDG_DATA_DIRS="$TMPDIR/share"
    mkdir -p "$HOME/.config/rice" "$HOME/.config/wallpaper" "$XDG_STATE_HOME/rice" "$XDG_RUNTIME_DIR"
    mkdir -p "$XDG_DATA_DIRS/icons/fixture-quill"
    touch "$XDG_DATA_DIRS/icons/fixture-quill/manifest.hl"
    custom_wallpaper="$TMPDIR/custom wallpaper.png"
    printf custom > "$custom_wallpaper"
    : > "$RICE_TEST_LOG"

    switch=${packages.riceSwitch}/bin/rice-switch
    reset_state() {
      printf %s cyberpunk > "$XDG_STATE_HOME/rice/active"
      printf '%s\n' "$custom_wallpaper" > "$HOME/.config/wallpaper/current"
      chmod 640 "$XDG_STATE_HOME/rice/active" "$HOME/.config/wallpaper/current"
      touch -d @1700000000 "$XDG_STATE_HOME/rice/active" "$HOME/.config/wallpaper/current"
      rm -f "$RICE_RELOAD_COUNT" "$RICE_MV_COUNT"
      unset RICE_FAIL_HYPR_MATCH RICE_FAIL_ROLLBACK_HYPR_MATCH RICE_FAIL_RELOAD_AT RICE_FAIL_WALLPAPER_MATCH RICE_FAIL_MV_AT RICE_FAIL_MV_AFTER RICE_SIGNAL_RELOAD RICE_BLOCK_HYPR_MATCH
      : > "$RICE_TEST_LOG"
    }
    expect_failure() {
      if "$@" >"$TMPDIR/stdout" 2>"$TMPDIR/stderr"; then
        echo "command unexpectedly succeeded: $*" >&2
        exit 1
      fi
    }

    echo "case: successful first run"
    rm -f "$XDG_STATE_HOME/rice/active"
    "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = lotm
    test "$(cat "$HOME/.config/wallpaper/current")" = ${lotmWallpaper}
    grep -q "awww img ${lotmWallpaper}" "$RICE_TEST_LOG"

    echo "case: compositor motion (D-047)"
    grep -q 'leaf = "windowsIn", enabled = true, speed = 4, bezier = "rice_enter", style = "popin 85%"' "$RICE_TEST_LOG"
    grep -q 'hl.curve("rice_enter", { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })' "$RICE_TEST_LOG"
    grep -q 'animations = { enabled = true }' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    "$switch" cyberpunk
    grep -q 'rgb(00e5ff)' "$RICE_TEST_LOG"
    # Baseline leaves come back; no theme curve is referenced.
    grep -q 'leaf = "windowsIn", enabled = true, speed = 6, bezier = "winIn", style = "slide"' "$RICE_TEST_LOG"
    grep -q 'leaf = "fadeIn", enabled = true, speed = 10, bezier = "default"' "$RICE_TEST_LOG"
    ! grep -q 'rice_' "$RICE_TEST_LOG"

    echo "case: window chrome (D-049)"
    grep -q 'active_border = "rgb(00e5ff)"' "$RICE_TEST_LOG"
    grep -q 'groupbar = { col = { active = "rgba(ffff0066)", inactive = "rgba(77770066)" }, text_color = "rgb(ffffff)", text_color_inactive = "rgb(ffffff)", font_family = "" }' "$RICE_TEST_LOG"
    grep -q 'leaf = "borderangle", enabled = false' "$RICE_TEST_LOG"
    ! grep -q 'Cinzel' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    "$switch" lotm
    grep -q 'active_border = { colors = { "rgb(d9a441)", "rgb(c79a3a)" }, angle = 45 }' "$RICE_TEST_LOG"
    grep -q 'border_active = { colors = { "rgb(d9a441)", "rgb(c79a3a)" }, angle = 45 }' "$RICE_TEST_LOG"
    grep -q 'groupbar = { col = { active = { colors = { "rgb(c79a3a)" }, angle = 90 } }, text_color = "rgb(0e0a06)", font_family = "Cinzel" }' "$RICE_TEST_LOG"
    grep -q 'leaf = "borderangle", enabled = true, speed = 8, bezier = "rice_standard", style = "once"' "$RICE_TEST_LOG"

    echo "case: square gilt windows (D-072)"
    grep -q 'inactive_border = { colors = { "rgb(2a211a)", "rgb(0e0a06)" }, angle = 45 }' "$RICE_TEST_LOG"
    grep -q 'hl.config({ general = { border_size = 3 }, decoration = { rounding = 0, shadow = { enabled = true, color = "rgba(0e0a06dd)", range = 18, render_power = 2, offset = "3 5" } } })' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    "$switch" cyberpunk
    # The generated config's shape comes back.
    grep -q 'hl.config({ general = { border_size = 2 }, decoration = { rounding = 16, shadow = { enabled = true, range = 4, render_power = 3, color = "rgba(1a1a1aee)", offset = "0 0" } } })' "$RICE_TEST_LOG"
    grep -q 'inactive_border = "rgb(141b2b)"' "$RICE_TEST_LOG"
    ! grep -q 'rounding = 0' "$RICE_TEST_LOG"

    echo "case: solid focus border, no colour fade (D-073)"
    : > "$RICE_TEST_LOG"
    "$switch" lotm
    grep -q 'hl.animation({ leaf = "border", enabled = false })' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    "$switch" cyberpunk
    grep -q 'leaf = "border", enabled = true, speed = 10, bezier = "liner"' "$RICE_TEST_LOG"
    ! grep -q 'leaf = "border", enabled = false' "$RICE_TEST_LOG"

    echo "case: theme cursor applies live, base cursor without one (D-048)"
    grep -q '^hypr setcursor capitaine-cursors-white 16$' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    "$switch" lotm
    grep -q '^hypr setcursor fixture-quill 24$' "$RICE_TEST_LOG"
    mv "$XDG_DATA_DIRS/icons/fixture-quill" "$TMPDIR/uninstalled-quill"
    reset_state
    expect_failure "$switch" lotm
    grep -q "cursor theme 'fixture-quill' is not installed" "$TMPDIR/stderr"
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk
    test ! -s "$RICE_TEST_LOG"
    mv "$TMPDIR/uninstalled-quill" "$XDG_DATA_DIRS/icons/fixture-quill"

    echo "case: reduce-motion disables compositor animation"
    printf '%s' '{"motion":{"reduce":true}}' > "$XDG_STATE_HOME/rice/prefs.json"
    : > "$RICE_TEST_LOG"
    "$switch" lotm
    grep -q 'animations = { enabled = false }' "$RICE_TEST_LOG"
    ! grep -q 'hl.animation' "$RICE_TEST_LOG"
    rm "$XDG_STATE_HOME/rice/prefs.json"

    echo "case: the daily accent never recolours window chrome (D-078)"
    printf '{"extras":{"tarotDraw":{"daily":{"date":"%s","id":"moon"}}}}' "$(date +%F)" > "$XDG_STATE_HOME/rice/prefs.json"
    : > "$RICE_TEST_LOG"
    "$switch" lotm
    grep -q 'active_border = { colors = { "rgb(d9a441)", "rgb(c79a3a)" }, angle = 45 }' "$RICE_TEST_LOG"
    ! grep -q 'dd7a6e' "$RICE_TEST_LOG"
    : > "$RICE_TEST_LOG"
    RICE_DAILY_ACCENT='#6fb2d6' "$RICE_HYPRLAND_THEME" --active
    ! grep -q '6fb2d6' "$RICE_TEST_LOG"
    rm "$XDG_STATE_HOME/rice/prefs.json"

    echo "case: HyprFM colours (D-055) follow a switch but never block it"
    # These fixture manifests lack the full colour tokens, so the adapter
    # fails once HyprFM is set up; the switch still lands.
    mkdir "$HOME/.config/hyprfm"
    "$switch" lotm 2> "$TMPDIR/hyprfm.err"
    test "$(cat "$XDG_STATE_HOME/rice/active")" = lotm
    grep -q 'could not update HyprFM colours' "$TMPDIR/hyprfm.err"
    rmdir "$HOME/.config/hyprfm"

    echo "case: trust boundary"
    reset_state
    printf %s '{}' > "$TMPDIR/mutable-index.json"
    expect_failure env RICE_INDEX="$TMPDIR/mutable-index.json" "$switch" lotm
    grep -q 'must resolve to /nix/store' "$TMPDIR/stderr"
    expect_failure env RICE_INDEX=${malformedIndex} "$switch" lotm
    grep -q 'invalid theme index' "$TMPDIR/stderr"
    printf %s '{}' > /build/rice-switch-mutable-manifest.json
    expect_failure env RICE_INDEX=${mutableManifestIndex} "$switch" mutable
    grep -q 'manifest.*must resolve to /nix/store' "$TMPDIR/stderr"
    expect_failure "$switch" invalid
    test ! -s "$RICE_TEST_LOG"

    echo "case: target Hyprland failure"
    reset_state
    export RICE_FAIL_HYPR_MATCH='rgb(c79a3a)'
    expect_failure "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk
    grep '^hypr eval ' "$RICE_TEST_LOG" | tail -n 1 | grep -q 'rgb(00e5ff)'
    grep '^hypr ' "$RICE_TEST_LOG" | tail -n 1 | grep -q 'setcursor capitaine-cursors-white'
    grep -q 'rollback completed' "$TMPDIR/stderr"

    echo "case: failed visual compensation recovery command"
    reset_state
    export RICE_FAIL_HYPR_MATCH='rgb(c79a3a)' RICE_FAIL_ROLLBACK_HYPR_MATCH='rgb(00e5ff)'
    expect_failure "$switch" lotm
    grep -q 'run rice-hyprland-theme --active' "$TMPDIR/stderr"
    grep -q 'PARTIAL ROLLBACK' "$TMPDIR/stderr"

    echo "case: Quickshell reload failure"
    reset_state
    pointer_mode=$(stat -c %a "$XDG_STATE_HOME/rice/active")
    pointer_mtime=$(stat -c %Y "$XDG_STATE_HOME/rice/active")
    export RICE_FAIL_RELOAD_AT=1
    expect_failure "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk
    test "$(stat -c %a "$XDG_STATE_HOME/rice/active")" = "$pointer_mode"
    test "$(stat -c %Y "$XDG_STATE_HOME/rice/active")" = "$pointer_mtime"
    test "$(cat "$RICE_RELOAD_COUNT")" = 2

    echo "case: no-prior-pointer rollback"
    reset_state
    rm "$XDG_STATE_HOME/rice/active"
    export RICE_FAIL_RELOAD_AT=1
    expect_failure "$switch" lotm
    test ! -e "$XDG_STATE_HOME/rice/active"

    echo "case: wallpaper failure"
    reset_state
    wallpaper_mode=$(stat -c %a "$HOME/.config/wallpaper/current")
    wallpaper_mtime=$(stat -c %Y "$HOME/.config/wallpaper/current")
    export RICE_FAIL_WALLPAPER_MATCH='lotm-wallpaper'
    expect_failure "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk
    test "$(cat "$HOME/.config/wallpaper/current")" = "$custom_wallpaper"
    test "$(stat -c %a "$HOME/.config/wallpaper/current")" = "$wallpaper_mode"
    test "$(stat -c %Y "$HOME/.config/wallpaper/current")" = "$wallpaper_mtime"
    grep -q "awww img $custom_wallpaper" "$RICE_TEST_LOG"
    if grep -q "awww img ${cyberWallpaper}" "$RICE_TEST_LOG"; then
      echo "rollback substituted the prior manifest wallpaper" >&2
      exit 1
    fi

    echo "case: no-prior-wallpaper failure"
    reset_state
    rm "$HOME/.config/wallpaper/current"
    export RICE_FAIL_WALLPAPER_MATCH='lotm-wallpaper'
    expect_failure "$switch" lotm
    test ! -e "$HOME/.config/wallpaper/current"
    grep -q 'no wallpaper was previously persisted' "$TMPDIR/stderr"
    grep -q 'PARTIAL ROLLBACK' "$TMPDIR/stderr"
    if grep -q "awww img ${cyberWallpaper}" "$RICE_TEST_LOG"; then
      echo "rollback invented a prior wallpaper" >&2
      exit 1
    fi

    echo "case: pointer commit failure"
    reset_state
    export RICE_FAIL_MV_AT=1
    expect_failure "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk

    echo "case: pointer rename reports failure after commit"
    reset_state
    export RICE_FAIL_MV_AT=1 RICE_FAIL_MV_AFTER=1
    expect_failure "$switch" lotm
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk

    echo "case: pointer restore failure"
    reset_state
    export RICE_FAIL_RELOAD_AT=1 RICE_FAIL_MV_AT=2
    expect_failure "$switch" lotm
    grep -q 'PARTIAL ROLLBACK' "$TMPDIR/stderr"

    echo "case: signal rollback"
    reset_state
    export RICE_SIGNAL_RELOAD=1
    set +e
    "$switch" lotm >"$TMPDIR/stdout" 2>"$TMPDIR/stderr"
    signal_status=$?
    set -e
    test "$signal_status" = 143
    test "$(cat "$XDG_STATE_HOME/rice/active")" = cyberpunk
    grep -q 'interrupted by signal TERM; rollback completed' "$TMPDIR/stderr"

    echo "case: lock contention"
    reset_state
    export RICE_BLOCK_HYPR_MATCH='rgb(c79a3a)'
    export RICE_BLOCK_ENTERED="$TMPDIR/block.entered" RICE_BLOCK_RELEASE="$TMPDIR/block.release"
    "$switch" lotm >"$TMPDIR/first.out" 2>"$TMPDIR/first.err" &
    first_pid=$!
    while [ ! -e "$RICE_BLOCK_ENTERED" ]; do sleep 0.01; done
    expect_failure "$switch" lotm
    grep -q 'another rice-switch transaction is in progress' "$TMPDIR/stderr"
    touch "$RICE_BLOCK_RELEASE"
    wait "$first_pid"

    test -z "$(find "$XDG_STATE_HOME/rice" -name '.active.*' -print -quit)"
    if grep -Eq 'nixos-rebuild|switch-to-configuration|--speciali[sz]e|_active-scheme\.nix|Sources/dotfiles' ${packages.riceSwitch}/bin/rice-switch; then
      echo "rice-switch contains a rebuild, specialization, or source-mutation path" >&2
      exit 1
    fi

    touch $out
  ''
