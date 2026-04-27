_: {
  flake.homeModules.programs-yazi =
    { lib, osConfig, config, ... }:
    let
      c = config.colorScheme.palette;
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.yazi = {
          enable = true;
          enableFishIntegration = true;

          settings = {
            manager = {
              show_hidden = true;
              sort_by = "natural";
              sort_dir_first = true;
              linemode = "size";
              show_symlink = true;
            };
            preview = {
              max_width = 1000;
              max_height = 1000;
              image_filter = "lanczos3";
            };
          };

          theme = {
            manager = {
              cwd = { fg = "#${c.base0D}"; };
              hovered = { bg = "#${c.base02}"; };
              preview_hovered = { underline = true; };
              find_keyword = { fg = "#${c.base0A}"; bold = true; };
              find_position = { fg = "#${c.base0E}"; italic = true; };
              marker_selected = { fg = "#${c.base0B}"; bg = "#${c.base0B}"; };
              marker_copied = { fg = "#${c.base0A}"; bg = "#${c.base0A}"; };
              marker_cut = { fg = "#${c.base08}"; bg = "#${c.base08}"; };
              tab_active = { fg = "#${c.base00}"; bg = "#${c.base0D}"; };
              tab_inactive = { fg = "#${c.base05}"; bg = "#${c.base02}"; };
              border_symbol = "│";
              border_style = { fg = "#${c.base03}"; };
            };
            status = {
              separator_open = "";
              separator_close = "";
              separator_style = { fg = "#${c.base02}"; bg = "#${c.base02}"; };
              mode_normal = { fg = "#${c.base00}"; bg = "#${c.base0D}"; bold = true; };
              mode_select = { fg = "#${c.base00}"; bg = "#${c.base0B}"; bold = true; };
              mode_unset = { fg = "#${c.base00}"; bg = "#${c.base0E}"; bold = true; };
              progress_label = { fg = "#${c.base05}"; bold = true; };
              progress_normal = { fg = "#${c.base0D}"; bg = "#${c.base02}"; };
              progress_error = { fg = "#${c.base08}"; bg = "#${c.base02}"; };
              permissions_t = { fg = "#${c.base0D}"; };
              permissions_r = { fg = "#${c.base0A}"; };
              permissions_w = { fg = "#${c.base08}"; };
              permissions_x = { fg = "#${c.base0B}"; };
              permissions_s = { fg = "#${c.base03}"; };
            };
            input = {
              border = { fg = "#${c.base0D}"; };
              title = { };
              value = { };
              selected = { reversed = true; };
            };
            select = {
              border = { fg = "#${c.base0D}"; };
              active = { fg = "#${c.base0E}"; };
              inactive = { };
            };
          };
        };
      };
    };
}
