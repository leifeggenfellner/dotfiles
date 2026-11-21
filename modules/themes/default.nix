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
      { config, lib, pkgs, ... }:
      let
        s = config.theme.style;
        c = name: "#${config.theme.colors.${name}}";
        accent = c s.accentPrimary;
        # libadwaita's named colours from the active palette. adw-gtk3 reads
        # the same names on GTK3, so both toolkits get one look.
        named = {
          accent_bg_color = accent;
          accent_fg_color = c "crust";
          accent_color = accent;
          window_bg_color = c "base";
          window_fg_color = c "text";
          view_bg_color = c "mantle";
          view_fg_color = c "text";
          headerbar_bg_color = c "crust";
          headerbar_fg_color = c "text";
          headerbar_border_color = c "surface1";
          headerbar_backdrop_color = c "mantle";
          headerbar_shade_color = "rgba(0, 0, 0, 0.36)";
          headerbar_darker_shade_color = "rgba(0, 0, 0, 0.6)";
          sidebar_bg_color = c "mantle";
          sidebar_fg_color = c "text";
          sidebar_backdrop_color = c "crust";
          sidebar_border_color = c "surface1";
          sidebar_shade_color = "rgba(0, 0, 0, 0.36)";
          secondary_sidebar_bg_color = c "base";
          secondary_sidebar_fg_color = c "text";
          secondary_sidebar_backdrop_color = c "mantle";
          secondary_sidebar_border_color = c "surface1";
          secondary_sidebar_shade_color = "rgba(0, 0, 0, 0.36)";
          card_bg_color = c "surface0";
          card_fg_color = c "text";
          card_shade_color = "rgba(0, 0, 0, 0.36)";
          dialog_bg_color = c "base";
          dialog_fg_color = c "text";
          popover_bg_color = c "surface0";
          popover_fg_color = c "text";
          popover_shade_color = "rgba(0, 0, 0, 0.36)";
          thumbnail_bg_color = c "surface0";
          thumbnail_fg_color = c "text";
          shade_color = "rgba(0, 0, 0, 0.36)";
          scrollbar_outline_color = "rgba(0, 0, 0, 0.5)";
          destructive_bg_color = c "red";
          destructive_fg_color = c "text";
          destructive_color = c "red";
          success_bg_color = c "green";
          success_fg_color = c "crust";
          success_color = c "green";
          warning_bg_color = c "yellow";
          warning_fg_color = c "crust";
          warning_color = c "yellow";
          error_bg_color = c "red";
          error_fg_color = c "text";
          error_color = c "red";
        };
        defineColors = lib.concatStrings (lib.mapAttrsToList (name: value: "@define-color ${name} ${value};\n") named);
        # libadwaita 1.6+ widgets read CSS variables, not the named colours.
        variables = ":root {\n"
          + lib.concatStrings (lib.mapAttrsToList (name: value: "  --${lib.replaceStrings [ "_" ] [ "-" ] name}: ${value};\n") named)
          + "}\n";
      in
      {
        gtk = {
          enable = true;
          theme = {
            name = "adw-gtk3-dark";
            package = pkgs.adw-gtk3;
          };
          font = {
            name = s.fontSans;
            package = pkgs.google-fonts.override { fonts = [ "Inter" ]; };
            size = 9;
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
          # Every scheme is dark; without this, GTK dialogs (file pickers,
          # Electron message boxes) open in light Adwaita.
          gtk3 = {
            extraConfig.gtk-application-prefer-dark-theme = true;
            extraCss = defineColors;
          };
          gtk4 = {
            extraConfig.gtk-application-prefer-dark-theme = true;
            # GTK4 apps keep libadwaita's own stylesheet; only the colours change.
            theme = null;
            extraCss = defineColors + variables;
          };
        };
        # The portal's color-scheme, read by GTK4/libadwaita and Electron.
        dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
      };
    themes-colors = colors;
  };
}
