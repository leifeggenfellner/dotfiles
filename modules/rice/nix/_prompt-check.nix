# Prompt flavour (D-050): LOTM builds a Starship config whose labels sit
# beside the real values, its fish snippet parses and maps workspaces,
# and Cyberpunk builds nothing (it keeps the base prompt).
{ pkgs, baseSettings }:
let
  inherit (pkgs) lib;
  mkPrompt = import ./_prompt-lib.nix { inherit pkgs lib; };
  build = themeName: mkPrompt {
    inherit themeName baseSettings;
    theme = import (../themes + "/${themeName}/_theme.nix");
  };
  lotm = build "lotm";
in
assert build "cyberpunk" == null;
pkgs.runCommand "rice-prompt"
{
  nativeBuildInputs = [ pkgs.fish pkgs.starship pkgs.git pkgs.gnugrep pkgs.gnused ];
}
  ''
    export HOME="$TMPDIR"
    fish --no-config -n ${lotm.fish}

    # Workspace label: a listed pathway, then the real-name fallback.
    mkdir bin
    printf '#!/bin/sh\necho "workspace %s (%s) on monitor DP-1:"\n' '$WS' '$WSNAME' > bin/hyprctl
    chmod +x bin/hyprctl
    export PATH="$PWD/bin:$PATH" HYPRLAND_INSTANCE_SIGNATURE=test
    test "$(WS=2 WSNAME=2 fish --no-config -c 'source ${lotm.fish}; echo $RICE_WORKSPACE')" = '☉ Door 2'
    test "$(WS=-98 WSNAME=special:x fish --no-config -c 'source ${lotm.fish}; echo $RICE_WORKSPACE')" = '☉ special:x'

    strip() { sed 's/\x1b\[[0-9;]*m//g'; }
    export STARSHIP_CONFIG=${lotm.toml} RICE_WORKSPACE='☉ Door 2'
    git init -q repo && cd repo && touch a b && git add a && echo x > a
    line="$(starship prompt --status 130 | strip)"
    echo "$line"
    grep -q '☉ Door 2' <<< "$line"
    grep -q 'failed ritual · 130 INT' <<< "$line"
    grep -q 'Sequence \[' <<< "$line"
    grep -q '?1' <<< "$line"
    starship prompt --status 0 | strip | grep -vq 'failed ritual'
    touch $out
  ''
