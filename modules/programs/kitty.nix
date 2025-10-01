{ osConfig
, config
, pkgs
, lib
, ...
}:
let
  cfg = config.program.kitty;
in
{
  options.program.kitty = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable kitty terminal (system-wide config & package)";
    };

    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Font size for kitty (points)";
    };
  };

  config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
    environment.systemPackages = [ pkgs.kitty ];

    environment.etc."xdg/kitty/kitty.conf".text = ''
      ## Fonts
      font_family FiraCode
      bold_font FiraCode Bold
      italic_font "JetBrainsMono Nerd Font"
      bold_italic_font "JetBrainsMonoNL Nerd Font"
      font_size ${toString cfg.fontSize}

      ## Colors
      foreground #${config.colorScheme.palette.base05}
      background #${config.colorScheme.palette.base00}

      cursor #${config.colorScheme.palette.base05}
      cursor_text_color #${config.colorScheme.palette.base06}

      # selection
      selection_foreground #${config.colorScheme.palette.base06}
      selection_background #${config.colorScheme.palette.base03}

      # highlight / focused match approximation
      active_tab_foreground #${config.colorScheme.palette.base06}
      active_tab_background #${config.colorScheme.palette.base0B}

      # Footer / status-like colors are approximated as hints in kitty
      # kitty does not have explicit footer color, but these are here for reference:
      # footer_bar.foreground -> ${config.colorScheme.palette.base06}
      # footer_bar.background -> ${config.colorScheme.palette.base01}

      # Window look
      background_opacity 0.91
      enable_italic true
      hide_cursor_when_typing no

      # padding
      window_padding_width 5

      # Palette (0..15 => normal + bright)
      color0  #${config.colorScheme.palette.base00}
      color1  #${config.colorScheme.palette.base08}
      color2  #${config.colorScheme.palette.base0B}
      color3  #${config.colorScheme.palette.base0A}
      color4  #${config.colorScheme.palette.base0D}
      color5  #${config.colorScheme.palette.base0E}
      color6  #${config.colorScheme.palette.base0C}
      color7  #${config.colorScheme.palette.base05}

      color8  #${config.colorScheme.palette.base01}
      color9  #${config.colorScheme.palette.base08}
      color10 #${config.colorScheme.palette.base0B}
      color11 #${config.colorScheme.palette.base0A}
      color12 #${config.colorScheme.palette.base0D}
      color13 #${config.colorScheme.palette.base0E}
      color14 #${config.colorScheme.palette.base0C}
      color15 #${config.colorScheme.palette.base07}

      # url handling: use mimeo for opening urls
      # kitty supports `url_open_command` which is executed with {url} substituted
      # We will use xdg-open by default but point to your mimeo binary if it exists in the store.
      url_open_command ${pkgs.mimeo}/bin/mimeo '{url}'

      # other niceties
      map_ctrl_plus_space_to all_modifiers no
    '';
  };
}
