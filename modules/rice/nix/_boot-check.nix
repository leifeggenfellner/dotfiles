# D-044 rebuild-time surfaces, for every bundled theme: the console
# palette has 16 entries that stay readable on its own background, and
# themes with `integration.boot` build a complete Plymouth script theme.
{ pkgs }:
let
  inherit (pkgs) lib;
  themeLib = import ./_themes-lib.nix { inherit lib; };
  themes = lib.mapAttrs (_: dir: import (dir + "/_theme.nix")) themeLib.bundledThemePackages;
  palettes = lib.mapAttrs
    (_: theme: import ./_console-palette.nix { inherit lib; } theme.palette.legacy)
    (lib.filterAttrs (_: theme: theme ? palette.legacy) themes);
  splashes = lib.mapAttrsToList
    (themeName: theme: import ./_plymouth-theme.nix { inherit pkgs lib; } { inherit themeName theme; })
    (lib.filterAttrs (_: theme: theme ? integration.boot) themes);
in
pkgs.runCommand "rice-boot"
{
  nativeBuildInputs = [ pkgs.python3 ];
  palettes = builtins.toJSON palettes;
  passAsFile = [ "palettes" ];
} ''
  python3 - "$palettesPath" <<'EOF'
  import json, sys

  def luminance(hex_):
      channels = [int(hex_[i:i + 2], 16) / 255 for i in (0, 2, 4)]
      linear = [c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4 for c in channels]
      return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]

  def contrast(a, b):
      hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
      return (hi + 0.05) / (lo + 0.05)

  failures = []
  for theme, colors in json.load(open(sys.argv[1])).items():
      if len(colors) != 16 or not all(len(c) == 6 for c in colors):
          failures.append(f"{theme}: expected 16 rrggbb colours, got {colors}")
          continue
      for index, color in enumerate(colors[1:], start=1):
          # 7/15 are the default and bright foreground; 8 is the dim
          # "bright black" used for hints, so it only has to stay visible.
          minimum = 7.0 if index in (7, 15) else 2.5 if index == 8 else 3.0
          ratio = contrast(color, colors[0])
          if ratio < minimum:
              failures.append(f"{theme}: colour {index} #{color} is {ratio:.2f}:1 on #{colors[0]}, needs {minimum}")
  if failures:
      sys.exit("\n".join(failures))
  EOF

  for splash in ${lib.escapeShellArgs splashes}; do
    for dir in "$splash"/share/plymouth/themes/*; do
      name="$(basename "$dir")"
      grep -qx "ScriptFile=$dir/$name.script" "$dir/$name.plymouth"
      ! grep -n '@[A-Za-z]*@' "$dir/$name.script"
      for image in sigil glow fog bullet ring-0 ring-59; do
        test -s "$dir/$image.png"
      done
    done
  done
  touch $out
''
