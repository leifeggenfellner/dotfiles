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
          xdg.configFile = lib.mkMerge (lib.mapAttrsToList
            (themeName: card: {
              "rice/fastfetch/${themeName}.jsonc".source = card.config;
            } // lib.optionalAttrs (card.image != null) {
              "rice/fastfetch/${themeName}.png".source = card.image;
            })
            cards);
          # Returns 1 (the base greeting runs) when the active theme has no
          # card. Terminals that draw images get the gilded PNG, encoded by
          # chafa (fastfetch's own sixel encoder draws nothing in foot) and
          # sized from the terminal's cell geometry; the rest keep the
          # card's braille logo.
          programs.fish.functions.__rice_fastfetch = ''
            set -q __rice_active[1]; or return 1
            set -l dir ${config.xdg.configHome}/rice/fastfetch
            test -r $dir/$__rice_active.jsonc; or return 1
            set -l format
            if test -r $dir/$__rice_active.png
                switch "$TERM"
                    case 'foot*' 'mlterm*' 'contour*'
                        set format sixels
                    case xterm-kitty xterm-ghostty
                        set format kitty
                end
            end
            if set -q format[1]
                set -l image (mktemp)
                if ${pkgs.chafa.bin}/bin/chafa -f $format -s 24x12 --animate off --probe off --polite on \
                        $dir/$__rice_active.png > $image
                    fastfetch -c $dir/$__rice_active.jsonc --logo-type raw --logo $image --logo-width 24 --logo-height 12
                    set -l status_ff $status
                    rm -f $image
                    return $status_ff
                end
                rm -f $image
            end
            fastfetch -c $dir/$__rice_active.jsonc
          '';
        })
      ]);
    };
}
