# Color format conversion helpers for Catppuccin palette.
# Usage:  let fmt = import ./_fmt.nix lib;  in fmt.rgba "cba6f7" "1.0"
lib:
let
  hexToRgbStr = hex:
    let
      r = toString (lib.trivial.fromHexString (builtins.substring 0 2 hex));
      g = toString (lib.trivial.fromHexString (builtins.substring 2 2 hex));
      b = toString (lib.trivial.fromHexString (builtins.substring 4 2 hex));
    in
    "${r}, ${g}, ${b}";
in
{
  # "rgba(203, 166, 247, 1.0)" — CSS / hyprlock
  rgba = hex: alpha: "rgba(${hexToRgbStr hex}, ${alpha})";

  # "rgb(cba6f7)" — Hyprland config
  rgb = hex: "rgb(${hex})";

  # "#cba6f7"
  hex = c: "#${c}";

  # "#cba6f7cc" — hex with alpha suffix (mako, etc.)
  hexAlpha = c: a: "#${c}${a}";

  # "203, 166, 247" — raw decimal RGB components
  rgbComponents = hexToRgbStr;
}
