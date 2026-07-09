# Dynamic palette — returns colors for the given scheme name.
# Usage: import ./_palette.nix { scheme = "catppuccin-mocha"; }
{ scheme, themePackages ? { } }:
let
  palettes = import ./_palettes.nix;
in
if builtins.hasAttr scheme palettes then palettes.${scheme}
else if builtins.hasAttr scheme themePackages then
  let theme = import (themePackages.${scheme} + "/_theme.nix"); in
    theme.palette.legacy or (throw "rice theme '${scheme}' must expose palette.legacy for the legacy color bridge")
else throw "unknown desktop theme scheme '${scheme}'"
