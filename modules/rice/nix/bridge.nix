# D-012: when rice is enabled, the active rice theme drives the
# classic theming pipeline — scheme points at the theme's legacy
# palette entry, so Hyprland borders, hyprlock, Qt, and the HM
# theme.colors bridge all recolor from the manifest source.
_: {
  flake.nixosModules.rice-bridge =
    { lib, config, ... }:
    {
      config = lib.mkIf config.rice.enable {
        environment.desktop.theme.scheme = lib.mkDefault config.rice.theme;
      };
    };
}
