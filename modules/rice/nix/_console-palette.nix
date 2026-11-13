# Linux virtual-console palette derived from a theme's `palette.legacy`
# (D-012 bridge, D-044). Returns the 16 "rrggbb" strings NixOS takes as
# `console.colors`, in VT order: 0 is the console background and 7 the
# default foreground. Bright 9–14 lighten their normal counterpart toward
# white, so every legacy palette yields a full set without extra keys.
{ lib }:
legacy:
let
  channel = hex: offset: lib.fromHexString (builtins.substring offset 2 hex);
  toByte = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));
  lighten = hex:
    lib.concatMapStrings
      (offset: let c = channel hex offset; in toByte (c + (255 - c) * 30 / 100))
      [ 0 2 4 ];
  normal = map (key: legacy.${key}) [ "red" "green" "yellow" "blue" "mauve" "teal" ];
in
[ legacy.crust ] ++ normal ++ [ legacy.subtext1 legacy.overlay0 ] ++ map lighten normal ++ [ legacy.text ]
