# Dynamic palette — returns colors for the given scheme name.
# Usage: (import ./_palette.nix) "catppuccin-mocha"
scheme:
let
  palettes = import ./_palettes.nix;
in
palettes.${scheme}
