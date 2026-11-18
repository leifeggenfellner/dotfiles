# Terminal tools (D-051): LOTM's fastfetch card renders as an aligned box
# with every base row, its bat theme compiles, and Cyberpunk opts into
# nothing (no card, no tools) so its configs stay the host's. Daily
# accents (D-054): every tarot card names a pathway with a text-safe
# accent (≥ 4.5:1 on bg.base) and a sigil, and has a card variant
# drawn in that accent. App themes (D-059): the VS Code extension carries
# a valid colour theme with code coloured by the shared roles, the Spotify
# scheme has every Spicetify key, and the Discord CSS only sets colour
# variables to resolved hex values. Zen (D-060): LOTM's chrome sheet only
# sets variables inside browser.xhtml, its new-tab page carries the
# masthead, epigraphs and feed script, and Cyberpunk gets neither.
{ pkgs }:
let
  inherit (pkgs) lib;
  themeDir = name: ../themes + "/${name}";
  theme = name: import (themeDir name + "/_theme.nix");
  card = name: import ./_fastfetch-lib.nix { inherit pkgs lib; } {
    themeName = name;
    themeDir = themeDir name;
    theme = theme name;
  };
  lotmTools = import ./_tools-lib.nix { inherit pkgs lib; } (theme "lotm");
  browser = name: import ./_browser-lib.nix { inherit pkgs lib; } {
    theme = theme name;
    feedPath = "/state/rice/newtab-feed.js";
    links = [{ label = "Example <b>"; url = "https://example.org"; }];
  };
  lotmBrowser = browser "lotm";
  lotmCards = (theme "lotm").widgets.tarotDraw.settings.cards;
  inherit (card "lotm") variants;
in
assert lib.all (c: c ? pathway && c ? accent && c ? sigil) lotmCards;
assert lib.attrNames variants == lib.sort lib.lessThan (map (c: c.id) lotmCards);
assert card "cyberpunk" == null;
assert (browser "cyberpunk").newtab == null && (browser "cyberpunk").zenChrome == null;
assert !((theme "cyberpunk") ? integration.tools);
assert lib.attrNames lotmTools.spotify == lib.sort lib.lessThan [
  "text"
  "subtext"
  "main"
  "main-elevated"
  "highlight"
  "highlight-elevated"
  "sidebar"
  "player"
  "card"
  "shadow"
  "selected-row"
  "button"
  "button-active"
  "button-disabled"
  "tab-active"
  "notification"
  "notification-error"
  "misc"
];
assert lib.all (v: builtins.match "[0-9a-f]{6}" v != null) (lib.attrValues lotmTools.spotify);
pkgs.runCommand "rice-tools"
{
  nativeBuildInputs = [ pkgs.fastfetch pkgs.bat pkgs.python3 pkgs.gnugrep pkgs.jq ];
}
  ''
    export HOME="$TMPDIR" USER=rice COLORTERM=truecolor
    fastfetch -c ${(card "lotm").config} > card.ansi 2>&1
    test -s ${(card "lotm").image}
    python3 - card.ansi <<'PY'
    import re, sys
    text = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", open(sys.argv[1], encoding="utf-8").read())
    box = [l[min(i for i in (l.find(c) for c in "╭│╰") if i >= 0):] for l in text.splitlines() if any(c in l for c in "╭│╰")]
    assert box and box[0].startswith("╭─ Beyonder Characteristic"), box
    assert len({len(l) for l in box}) == 1, [len(l) for l in box]
    # The sandbox has no os-release or package db; those rows are checked live.
    for label, key in [("Vessel", "user"), ("Sequence", "kernel")]:
        assert any(label in l and key in l for l in box), (label, key)
    assert "⣿" in text or any(0x2800 <= ord(c) <= 0x28ff for c in text), "logo missing"
    PY

    python3 - ${lib.escapeShellArg (theme "lotm").tokens.colors.bg.base} ${lib.escapeShellArgs (map (c: "${c.id}=${c.accent}") lotmCards)} <<'PY'
    import sys
    def luminance(hex_):
        channels = [int(hex_[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
        return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]
    base = luminance(sys.argv[1])
    for pair in sys.argv[2:]:
        card, accent = pair.split("=")
        hi, lo = sorted((luminance(accent), base), reverse=True)
        ratio = (hi + 0.05) / (lo + 0.05)
        assert ratio >= 4.5, f"{card}: accent {accent} is {ratio:.2f}:1 on bg.base, needs 4.5"
    PY
    fastfetch -c ${variants.moon.config} > moon.ansi 2>&1
    grep -q '38;2;221;122;110m╭─ Beyonder Characteristic' moon.ansi
    test -s ${variants.moon.image}
    ! cmp -s ${variants.moon.image} ${(card "lotm").image}

    mkdir -p bat/themes
    cp ${lotmTools.bat} bat/themes/rice.tmTheme
    bat cache --build --source bat --target cache > /dev/null
    echo 'let x = "y"; # note' | BAT_CACHE_PATH=cache bat --theme rice --color always --paging never -l nix --style plain > bat.ansi
    grep -q '38;2;134;163;97m' bat.ansi   # strings: state.ok
    grep -q '38;2;133;117;86m' bat.ansi   # comments: fg.subtle
    grep -c 'theme\[' ${lotmTools.btop} | grep -qx 42

    ext=${lotmTools.vscode}/share/vscode/extensions/rice.rice-theme
    jq -e '.contributes.themes[0].label == "Lord of the Mysteries" and .contributes.themes[0].uiTheme == "vs-dark"' $ext/package.json > /dev/null
    jq -e '(.colors | length) > 100 and (.tokenColors | length) == 23
      and ([.colors[], .tokenColors[].settings.foreground] | all(test("^#[0-9a-f]{6}([0-9a-f]{2})?$")))
      and .colors["editor.background"] == "#1b1510"
      and (.tokenColors[] | select(.name == "String") | .settings.foreground) == "#86a361"' \
      $ext/themes/rice-color-theme.json > /dev/null

    zen=${lotmBrowser.zenChrome}
    head -1 $zen | grep -qx '@-moz-document url("chrome://browser/content/browser.xhtml") {'
    ! grep -vE '^(@-moz-document .*\{|  [:.a-z, *-]+ \{|    (color-scheme|font-family|color|--[a-z0-9-]+): [^;{}]+;|  \}|\}|)$' $zen

    page=${lotmBrowser.newtab}/index.html
    grep -q '<title>The Backlund Daily</title>' $page
    grep -q '<script src="file:///state/rice/newtab-feed.js"></script>' $page
    grep -q 'Quiet instruments reveal what loud rituals conceal' $page
    grep -q '"label":"Example <b>"' $page

    css=${lotmTools.discord}
    grep -q '^ \* @name Lord of the Mysteries (rice)$' $css
    ! grep -vE '^(/\*\*| \*.*|\.theme-dark, .*\{|  --[a-z0-9-]+: #[0-9a-f]{6}([0-9a-f]{2})?;|\}|)$' $css
    touch $out
  ''
