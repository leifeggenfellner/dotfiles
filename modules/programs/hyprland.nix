_: {
  flake.homeModules.programs-hyprland =
    { lib
    , pkgs
    , config
    , osConfig
    , ...
    }:
    let
      themeLib = import ../rice/nix/_themes-lib.nix { inherit lib; };
      palette = import ../themes/_palette.nix {
        scheme = osConfig.environment.desktop.theme.scheme;
        themePackages = if (osConfig.rice.enable or false) then themeLib.themePackages osConfig.rice else { };
      };
      fmt = import ../themes/_fmt.nix lib;
      style = osConfig.environment.desktop.theme.style;
      activeBorder = palette.${style.accentPrimary};
      q = builtins.toJSON;
      luaBool = value: if value then "true" else "false";
      hyprTheme = ''
        return {
            rice_enabled = ${luaBool (osConfig.rice.enable or false)},
            quickshell = ${q "${pkgs.quickshell}/bin/quickshell"},
            style = {
                rounding = ${toString style.rounding},
                gaps_inner = ${toString style.gapsInner},
                gaps_outer = ${toString style.gapsOuter},
                border_width = ${toString style.borderWidth},
                opacity_active = ${toString style.opacityActive},
                opacity_inactive = ${toString style.opacityInactive},
                blur_size = ${toString style.blurSize},
                blur_passes = ${toString style.blurPasses},
                blur_contrast = ${toString style.blurContrast},
                blur_brightness = ${toString style.blurBrightness},
                blur_noise = ${toString style.blurNoise},
                font_size_small = ${toString style.fontSizeSmall},
                cursor_name = ${q style.cursorName},
                cursor_size = ${toString style.cursorSize},
            },
            colors = {
                active_border = ${q (fmt.rgb activeBorder)},
                inactive_border = ${q (fmt.rgb palette.surface0)},
            },
        }
      '';
    in
    {

      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home = {
          packages = [
            pkgs.arandr # screen layout manager
            pkgs.bottom # alternative to htop & ytop
            pkgs.ffmpegthumbnailer # thumbnailer for video files
            pkgs.glib # Core application building blocks library (used by GTK/GNOME apps)
            pkgs.gnome-calendar # Calendar application from the GNOME desktop
            pkgs.gnome-boxes # Simple virtual machine manager from GNOME
            pkgs.gnome-weather # Weather application from the GNOME desktop
            pkgs.gnome-system-monitor # System resource monitor from GNOME
            pkgs.headsetcontrol # control logitech headsets
            pkgs.imagemagick # image manipulation
            pkgs.paprefs # pulseaudio preferences
            pkgs.pavucontrol # pulseaudio volume control
            pkgs.poppler # pdf tools
            pkgs.pulsemixer # pulseaudio volume control
            pkgs.scrot # screenshot tool
            pkgs.slurp # select a region in a wayland compositor
            pkgs.wayshot # screenshot tool
            pkgs.wgetpaste # paste to pastebin
            pkgs.cliphist # clipboard history store
            pkgs.wl-clipboard # wayland clipboard manager
            pkgs.wl-clip-persist # keep clipboard content after clients exit
            pkgs.wl-gammactl # wayland gamma control
          ];
          sessionVariables = {
            SSH_AUTH_SOCK = "/run/user/1000/keyring/ssh";
            XDG_CURRENT_DESKTOP = "Hyprland";
            XDG_SESSION_DESKTOP = "Hyprland";
            XDG_SESSION_TYPE = "wayland";
            SDL_VIDEODRIVER = "wayland";
            QT_AUTO_SCREEN_SCALE_FACTOR = 1;
            QT_QPA_PLATFORM = "wayland;xcb";
            QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
            QT_QPA_PLATFORMTHEME = "qt5ct";
            HYPRLAND_CONFIG = "${config.xdg.configHome}/hypr/hyprland.lua";
            DOTFILES_RICE_ENABLE = if osConfig.rice.enable or false then "1" else "0";
          };
        };

        xdg.configFile."hypr/hyprland.lua".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/Sources/dotfiles/hypr/hyprland.lua";
        xdg.configFile."hypr/theme.lua".text = hyprTheme;
      };
    };
}
