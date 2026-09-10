# rice-switch and rice-hyprland-theme implement the mutable half of the
# two-layer theme switch (D-003, D-018, D-039). Package construction lives in
# underscore-prefixed helpers so the same generated programs can be exercised
# by focused flake checks without importing this Home Manager module.
_: {
  flake.homeModules.rice-switch =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      packages = import ./_switch-package.nix { inherit pkgs; };
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [ packages.riceSwitch packages.hyprlandTheme ];
      };
    };
}
