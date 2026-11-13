# Rebuild-time system surfaces for the configured rice theme (D-044):
# the Plymouth boot splash from `integration.boot`, and the Linux
# virtual-console palette from `palette.legacy`. Both follow
# `rice.theme` and its specialisations (each boot entry carries its own
# initrd and kernel parameters); neither can follow `rice-switch`.
# Themes without `integration.boot` keep the host's existing splash.
_: {
  flake.nixosModules.rice-boot =
    { lib, pkgs, config, ... }:
    let
      cfg = config.rice;
      themeLib = import ./_themes-lib.nix { inherit lib; };
      mkThemeManifest = import ./_manifest-lib.nix { inherit pkgs lib; };
      themeDir = themeLib.themePackage cfg cfg.theme;
      theme = import (themeDir + "/_theme.nix");
      inherit (mkThemeManifest { themeName = cfg.theme; inherit themeDir theme; }) validated;
      boot = theme.integration.boot or null;
      splash = import ./_plymouth-theme.nix { inherit pkgs lib; } { themeName = cfg.theme; inherit theme; };
    in
    {
      config = lib.mkIf cfg.enable (lib.mkMerge [
        (lib.mkIf (theme ? palette.legacy) {
          console.colors = import ./_console-palette.nix { inherit lib; } theme.palette.legacy;
        })
        (lib.mkIf (boot != null) {
          boot.plymouth = {
            enable = true;
            theme = assert validated; splash.name;
            themePackages = [ splash ];
          } // lib.optionalAttrs (boot ? font) {
            font = "${boot.font}";
          };
        })
      ]);
    };
}
