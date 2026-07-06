# Installs the Nix-default theme's validated manifest at the
# runtime's fallback path (~/.config/rice/manifest.json) and the
# all-themes index (~/.config/rice/themes.json) the switch
# machinery reads (D-003, D-018). Validation and the raster
# pipeline live in _manifest-lib.nix; index assembly and preview
# derivation in _index-lib.nix.
_: {
  flake.homeModules.rice-manifest =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      mkThemeManifest = import ./_manifest-lib.nix { inherit pkgs lib; };
      mkThemeIndex = import ./_index-lib.nix { inherit pkgs lib; };
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        xdg.configFile."rice/manifest.json".source = (mkThemeManifest {
          themeName = cfg.theme;
          themeDir = ../themes + "/${cfg.theme}";
        }).json;
        xdg.configFile."rice/themes.json".source =
          (mkThemeIndex { defaultTheme = cfg.theme; }).json;
      };
    };
}
