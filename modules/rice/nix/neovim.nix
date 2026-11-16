# Neovim flavour that follows the active rice (D-052): every packaged
# theme with `widgets.terminal.settings.neovim` gets a generated data
# module; the theme-blind loader (modules/rice/nvim) picks the active
# theme's at startup. Themes without one leave the editor as configured.
_: {
  flake.homeModules.rice-neovim =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      themeLib = import ./_themes-lib.nix { inherit lib; };
      mkModule = import ./_neovim-lib.nix { inherit pkgs lib; };
      modules = lib.filterAttrs (_: m: m != null) (lib.mapAttrs
        (themeName: dir: mkModule { inherit themeName; theme = import (dir + "/_theme.nix"); })
        (themeLib.themePackages cfg));
    in
    {
      config = lib.mkIf ((cfg.enable or false) && config.programs.neovim.enable && modules != { }) {
        xdg.configFile = {
          "nvim/lua/rice/init.lua".source = ../nvim/rice/init.lua;
          "nvim/lua/rice/start.lua".source = ../nvim/rice/start.lua;
        } // lib.mapAttrs'
          (themeName: m: lib.nameValuePair "nvim/lua/rice/themes/${themeName}.lua" { source = m; })
          modules;
        programs.neovim.initLua = lib.mkAfter ''
          pcall(function() require("rice").setup() end)
        '';
      };
    };
}
