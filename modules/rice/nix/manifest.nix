# Installs the active theme's validated manifest at the runtime's
# manifest path (~/.config/rice/manifest.json). Validation and the
# raster pipeline live in _manifest-lib.nix (mkThemeManifest).
_: {
  flake.homeModules.rice-manifest =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      mkThemeManifest = import ./_manifest-lib.nix { inherit pkgs lib; };
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        xdg.configFile."rice/manifest.json".source = (mkThemeManifest {
          themeName = cfg.theme;
          themeDir = ../themes + "/${cfg.theme}";
        }).json;
      };
    };
}
