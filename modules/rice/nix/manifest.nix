# Serializes the active theme's manifest source to the runtime's
# manifest path. Phase-4 minimal wiring: no validation or index yet
# (that machinery is Phase 7 / mkThemeManifest per
# docs/architecture/contracts/theme-manifest.md).
_: {
  flake.homeModules.rice-manifest =
    { lib, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      manifest = import (../themes + "/${cfg.theme}/_theme.nix");
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        xdg.configFile."rice/manifest.json".text = builtins.toJSON manifest;
      };
    };
}
