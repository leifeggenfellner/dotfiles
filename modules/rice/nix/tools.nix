# Terminal tools dressed by the rice (D-051). The configured theme's
# `integration.tools` swaps in token-derived btop/bat/yazi/cava themes at
# rebuild; every packaged theme's `widgets.terminal.settings.fastfetch`
# becomes a card the greeting picks from the active theme at startup.
_: {
  flake.homeModules.rice-tools =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      themeLib = import ./_themes-lib.nix { inherit lib; };
      themeDir = themeLib.themePackage cfg cfg.theme;
      theme = import (themeDir + "/_theme.nix");
      tools = theme.integration.tools or [ ];
      generated = import ./_tools-lib.nix { inherit pkgs lib; } theme;
      wants = tool: lib.elem tool tools && config.programs.${tool}.enable;

      mkCard = import ./_fastfetch-lib.nix { inherit pkgs lib; };
      cards = lib.filterAttrs (_: c: c != null) (lib.mapAttrs
        (themeName: dir: mkCard { inherit themeName; themeDir = dir; theme = import (dir + "/_theme.nix"); })
        (themeLib.themePackages cfg));
    in
    {
      config = lib.mkIf (cfg.enable or false) (lib.mkMerge [
        (lib.mkIf (wants "btop") {
          xdg.configFile."btop/themes/rice.theme".source = generated.btop;
          programs.btop.settings.color_theme = "rice";
        })
        (lib.mkIf (wants "bat") {
          programs.bat.themes.rice.src = generated.bat;
          programs.bat.config.theme = "rice";
        })
        (lib.mkIf (wants "yazi") {
          programs.yazi.theme = generated.yazi;
        })
        (lib.mkIf (wants "cava") {
          programs.cava.settings.color = generated.cava;
        })
        (lib.mkIf (cards != { }) {
          xdg.configFile = lib.mapAttrs'
            (themeName: card: lib.nameValuePair "rice/fastfetch/${themeName}.jsonc" { source = card; })
            cards;
          # Returns 1 (the base greeting runs) when the active theme has no card.
          programs.fish.functions.__rice_fastfetch = ''
            set -q __rice_active[1]; or return 1
            set -l card ${config.xdg.configHome}/rice/fastfetch/$__rice_active.jsonc
            test -r $card; or return 1
            fastfetch -c $card
          '';
        })
      ]);
    };
}
