_:
let
  colors = import ./_colors.nix;
in
{
  flake.homeModules = {
    themes-style =
      { lib, osConfig, ... }:
      {
        # HM alias — modules read `config.theme.style.*` which mirrors
        # the NixOS-side `environment.desktop.theme.style` options.
        options.theme.style = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Visual style parameters (mirrored from NixOS environment.desktop.theme.style)";
        };
        config.theme.style = osConfig.environment.desktop.theme.style;
      };
    themes-palette =
      { lib, osConfig, ... }:
      let
        themeLib = import ../rice/nix/_themes-lib.nix { inherit lib; };
        palette = import ./_palette.nix {
          scheme = osConfig.environment.desktop.theme.scheme;
          themePackages = if (osConfig.rice.enable or false) then themeLib.themePackages osConfig.rice else { };
        };
      in
      {
        options.theme.colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = palette;
          description = "Full named color palette (hex without #)";
        };
      };
    themes-gtk =
      { config, pkgs, ... }:
      let
        s = config.theme.style;
      in
      {
        gtk = {
          enable = true;
          font = {
            name = s.fontSans;
            package = pkgs.google-fonts.override { fonts = [ "Inter" ]; };
            size = 9;
          };
          theme = {
            name = "Flat-Remix-GTK-White-Dark";
            package = pkgs.flat-remix-gtk;
          };
          iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
          };
          cursorTheme = {
            name = s.cursorName;
            package = pkgs.capitaine-cursors;
            size = s.cursorSize;
          };
          gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
        };
      };
    themes-colors = colors;
  };
}
