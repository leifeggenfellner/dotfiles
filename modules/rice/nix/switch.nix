# rice-switch and rice-hyprland-theme (plus the theme cursors it applies)
# implement the mutable half of the
# two-layer theme switch (D-003, D-018, D-039). Package construction lives in
# underscore-prefixed helpers so the same generated programs can be exercised
# by focused flake checks without importing this Home Manager module.
_: {
  flake.homeModules.rice-switch =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      packages = import ./_switch-package.nix { inherit pkgs; };
      themeLib = import ./_themes-lib.nix { inherit lib; };
      cursorLib = import ./_cursor-theme.nix { inherit pkgs lib; };
      # Every packaged theme's cursor (D-048), so the adapter can apply
      # any of them live; it refuses a cursor that is not installed.
      cursors = lib.filter (p: p != null) (lib.mapAttrsToList
        (themeName: themeDir: cursorLib.package { inherit themeName; theme = import (themeDir + "/_theme.nix"); })
        (themeLib.themePackages cfg));
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [ packages.riceSwitch packages.hyprlandTheme packages.hyprfmTheme ] ++ cursors;
      };
    };
}
