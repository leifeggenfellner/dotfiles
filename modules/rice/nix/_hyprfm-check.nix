# HyprFM colours (D-055): rice-hyprfm-theme maps a theme's colour tokens
# onto HyprFM's keys (never the daily accent, D-079), derives a 16-colour terminal palette from palette.legacy only
# when it is complete, recolours Adwaita's folders into a "rice" icon
# theme, and writes nothing where HyprFM is not set up.
{ pkgs }:
let
  adapter = (import ./_switch-package.nix { inherit pkgs; }).hyprfmTheme;
  colors = {
    bg = { base = "#1b1510"; mantle = "#151009"; sunken = "#0e0a06"; surface1 = "#3e3121"; surface2 = "#55432c"; };
    fg = { primary = "#e6d7b8"; muted = "#b5a284"; subtle = "#857556"; };
    accent.primary = "#c79a3a";
    state = { ok = "#86a361"; warn = "#d9a441"; danger = "#b54834"; };
  };
  legacy = {
    surface1 = "3e3121";
    surface2 = "55432c";
    subtext1 = "cbbb99";
    text = "e6d7b8";
    red = "b54834";
    green = "86a361";
    yellow = "d9a441";
    blue = "9db4c0";
    mauve = "c79a3a";
    teal = "7d9b82";
  };
  manifest = pkgs.writeText "hyprfm-manifest.json" (builtins.toJSON {
    tokens.colors = colors;
    palette.legacy = legacy;
    widgets = {
      tarotDraw.settings.cards = [{ id = "fool"; } { id = "moon"; accent = "#dd7a6e"; }];
      dailyAccent.settings = { record = "extras.tarotDraw.daily"; catalog = "widgets.tarotDraw.settings.cards"; };
    };
  });
  partial = pkgs.writeText "hyprfm-partial.json" (builtins.toJSON {
    tokens.colors = colors;
    palette.legacy = removeAttrs legacy [ "teal" ];
  });
  broken = pkgs.writeText "hyprfm-broken.json" (builtins.toJSON {
    tokens.colors = colors // { accent.primary = "gold"; };
  });
  index = pkgs.writeText "rice-themes.json" (builtins.toJSON {
    schemaVersion = 1;
    default = "lotm";
    themes.lotm = { displayName = "LOTM"; inherit manifest; wallpapers = [ ]; };
  });
in
pkgs.runCommand "rice-hyprfm"
{
  nativeBuildInputs = [ pkgs.coreutils pkgs.gnugrep pkgs.shellcheck ];
}
  ''
    shellcheck -e SC2016 ${adapter}/bin/rice-hyprfm-theme
    export HOME="$TMPDIR/home" XDG_STATE_HOME="$TMPDIR/state" RICE_INDEX=${index}
    mkdir -p "$HOME" "$XDG_STATE_HOME/rice"
    theme="$HOME/.config/hyprfm/themes/rice.toml"
    run=${adapter}/bin/rice-hyprfm-theme

    # Not set up: nothing is written.
    $run --active
    test ! -e "$HOME/.config/hyprfm"

    mkdir -p "$HOME/.config/hyprfm"
    $run --active
    grep -qx 'accent = "#c79a3a"' "$theme"
    grep -qx 'crust = "#0e0a06"' "$theme"
    grep -qx 'muted = "#857556"' "$theme"
    test "$(grep -c '^    "#' "$theme")" = 16
    # Black is the surface; bright red lightens b54834 by 30%.
    grep -A1 '^palette' "$theme" | grep -q '"#3e3121"'
    grep -q '"#cb7e70"' "$theme"

    # The daily accent stays in the terminal greeting (D-079).
    printf '{"extras":{"tarotDraw":{"daily":{"date":"%s","id":"moon"}}}}' "$(date +%F)" > "$XDG_STATE_HOME/rice/prefs.json"
    RICE_DAILY_ACCENT='#8899ee' $run --active
    grep -qx 'accent = "#c79a3a"' "$theme"

    # The "rice" icon theme: Adwaita's folders in the accent, by role.
    icons="$HOME/.local/share/icons/rice"
    grep -qx 'Inherits=Adwaita,hicolor' "$icons/index.theme"
    test "$(ls "$icons/scalable/places" | wc -l)" = "$(ls ${pkgs.adwaita-icon-theme}/share/icons/Adwaita/scalable/places/{folder,folder-*,user-home,user-desktop,user-bookmarks}.svg | wc -l)"
    grep -q 'fill="#c79a3a"' "$icons/scalable/places/folder.svg"         # front
    grep -q 'stop-color="#af8733"' "$icons/scalable/places/folder.svg"   # rim: darkened 12%
    grep -q 'fill="#8f6e29"' "$icons/scalable/places/folder.svg"         # back: darkened 28%
    ! grep -qiE '#(62a0ea|438de6|a4caee|afd4ff|c0d5ea)' "$icons"/scalable/places/*.svg
    test -z "$(find "$icons" -name '.rice.*' -print -quit)"

    # An incomplete legacy palette leaves the terminal on HyprFM's own.
    $run --print --manifest ${partial} > partial.toml
    grep -qx 'accent = "#c79a3a"' partial.toml
    ! grep -q terminal partial.toml

    # Bad tokens fail without touching the written theme.
    cp "$theme" before.toml
    ! $run --manifest ${broken} 2> err
    grep -q 'not all #rrggbb' err
    cmp before.toml "$theme"
    test -z "$(find "$HOME/.config/hyprfm/themes" -name '.rice.*' -print -quit)"
    touch $out
  ''
