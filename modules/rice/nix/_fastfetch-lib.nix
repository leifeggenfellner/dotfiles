# fastfetch card from `widgets.terminal.settings.fastfetch` (D-051).
# Theme copy (a title and one diegetic label per row) and an asset logo
# go in; one fastfetch config per theme comes out, chosen at greeting
# time from the active theme. Rows and values match the base greeting,
# so the card loses nothing: each label sits beside the plain key.
{ pkgs, lib }:
{ themeName, themeDir, theme }:
let
  card = theme.widgets.terminal.settings.fastfetch or null;
  fmt = import ../../themes/_fmt.nix lib;
  colors = theme.tokens.colors;
  ansi = c: fmt.ansiJson (builtins.substring 1 6 c);

  labels = card.labels or { };
  label = key: labels.${key} or key;
  labelWidth = lib.foldl' lib.max 0 (map lib.stringLength (lib.attrValues labels));
  # Copy and keys are ASCII; the box lines are not, so repeat, never pad.
  repeat = n: s: lib.concatStrings (lib.replicate (lib.max 0 n) s);
  pad = width: s: s + repeat (width - lib.stringLength s) " ";

  # Nerd Font glyph by codepoint (BMP private use; astral ones need a pair).
  nf = code: builtins.fromJSON "\"${code}\"";

  # Same rows and glyphs as the base greeting (programs/fastfetch.nix).
  rows = [
    { key = "user"; glyph = nf "\\uf007"; type = "command"; text = "printf '%s@%s' \"$USER\" \"$(hostname)\""; value = "{}"; }
    { key = "distro"; glyph = nf "\\udb84\\udd05"; type = "os"; value = "{pretty-name}"; }
    { key = "kernel"; glyph = nf "\\uf31a"; type = "kernel"; value = "{release}"; }
    { key = "uptime"; glyph = nf "\\udb84\\udfab"; type = "command"; text = "${pkgs.procps}/bin/uptime -p | cut -d ' ' -f 2-"; value = "{}"; }
    { key = "shell"; glyph = nf "\\uf489"; type = "shell"; value = "{pretty-name}"; }
    { key = "mem"; glyph = nf "\\udb80\\udf5b"; type = "command"; text = "free -m | awk 'NR==2{printf \"%.1f GiB / %.1f GiB\",$3/1024,$2/1024}'"; value = "{}"; }
    { key = "pkgs"; glyph = nf "\\uf487"; type = "packages"; value = "{all}"; }
  ];

  valueWidth = 24;
  # "│ G Label···· key···· ▐ value··· │"
  inner = 1 + 2 + labelWidth + 1 + 6 + 3 + valueWidth + 1;
  title = card.title or "";
  top = "╭─ " + title + " " + repeat (inner - lib.stringLength title - 3) "─" + "╮";
  bottom = "╰" + repeat inner "─" + "╯";

  row = r: {
    inherit (r) type;
    key = "│ {$2}${r.glyph}{$1} {$2}${pad labelWidth (label r.key)}{$1} {$3}${pad 6 r.key}{$1}";
    format = " {$3}▐{$1} {$4}${lib.removeSuffix "}" r.value}>${toString valueWidth}}{$1} │";
  } // lib.optionalAttrs (r ? text) { inherit (r) text; };

  # The theme's single-colour SVG, gilded with accent.primary and drawn in
  # braille so it prints in any terminal.
  logo = pkgs.runCommand "rice-${themeName}-fastfetch-logo"
    { nativeBuildInputs = [ pkgs.resvg pkgs.imagemagick pkgs.chafa ]; }
    ''
      resvg --width 400 ${themeDir + "/assets/${card.logo}"} sigil.png
      magick sigil.png -fill '${colors.accent.primary}' -colorize 100 gilded.png
      chafa --format symbols --symbols braille --fg-only --size 26x13 -c full --threshold 0.3 \
        --animate off --polite on gilded.png > $out
    '';

  config = pkgs.writeText "rice-${themeName}-fastfetch.jsonc" (builtins.toJSON {
    "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
    logo = if card ? logo then { type = "file-raw"; source = "${logo}"; padding = { top = 1; right = 2; }; } else { type = "none"; };
    display = {
      separator = "";
      key.paddingLeft = 2;
      color.output = "white";
      constants = [
        (ansi colors.fg.primary)
        (ansi colors.accent.primary)
        (ansi colors.fg.subtle)
        (ansi colors.fg.primary)
      ];
    };
    modules = [
      "break"
      { type = "custom"; key = "{$2}${top}{$1}"; }
    ]
    ++ map row rows
    ++ [
      { type = "custom"; key = "{$2}${bottom}{$1}"; }
      "break"
      { type = "colors"; paddingLeft = 4; symbol = "circle"; block = { range = [ 0 15 ]; width = 3; }; }
      "break"
    ];
  });
in
if card == null then null else config
