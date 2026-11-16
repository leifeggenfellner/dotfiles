# Terminal tools (D-051): LOTM's fastfetch card renders as an aligned box
# with every base row, its bat theme compiles, and Cyberpunk opts into
# nothing (no card, no tools) so its configs stay the host's.
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
in
assert card "cyberpunk" == null;
assert !((theme "cyberpunk") ? integration.tools);
pkgs.runCommand "rice-tools"
{
  nativeBuildInputs = [ pkgs.fastfetch pkgs.bat pkgs.python3 pkgs.gnugrep ];
}
  ''
    export HOME="$TMPDIR" USER=rice COLORTERM=truecolor
    fastfetch -c ${card "lotm"} > card.ansi 2>&1
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

    mkdir -p bat/themes
    cp ${lotmTools.bat} bat/themes/rice.tmTheme
    bat cache --build --source bat --target cache > /dev/null
    echo 'let x = "y"; # note' | BAT_CACHE_PATH=cache bat --theme rice --color always --paging never -l nix --style plain > bat.ansi
    grep -q '38;2;134;163;97m' bat.ansi   # strings: state.ok
    grep -q '38;2;133;117;86m' bat.ansi   # comments: fg.subtle
    grep -c 'theme\[' ${lotmTools.btop} | grep -qx 42
    touch $out
  ''
