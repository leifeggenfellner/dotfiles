# D-012: when rice is enabled, the active rice theme drives the
# classic theming pipeline — scheme points at the theme's legacy
# palette entry, so Hyprland borders, hyprlock, Qt, and the HM
# theme.colors bridge all recolor from the manifest source.
# A theme cursor (D-048) also becomes the rebuild-time cursor, so GTK,
# XWayland and Hyprland's first frame start on it.
_: {
  flake.nixosModules.rice-bridge =
    { lib, config, ... }:
    let
      themeLib = import ./_themes-lib.nix { inherit lib; };
      theme = import (themeLib.themePackage config.rice config.rice.theme + "/_theme.nix");
      cursor = theme.integration.cursor or null;
    in
    {
      config = lib.mkIf config.rice.enable {
        environment.desktop.theme.scheme = lib.mkDefault config.rice.theme;
        environment.desktop.theme.style = lib.mkIf (cursor != null) {
          cursorName = lib.mkDefault cursor.name;
          cursorSize = lib.mkDefault cursor.size;
        };
      };
    };
}
