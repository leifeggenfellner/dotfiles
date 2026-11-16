# Starship prompt flavour that follows the active rice (D-050). Every
# packaged theme with `widgets.terminal.settings.prompt` gets its own
# Starship config and fish snippet at rebuild; fish sources the active
# theme's snippet at startup (`__rice_active`, set by rice-query's
# module). Themes without one keep the base prompt.
_: {
  flake.homeModules.rice-prompt =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      themeLib = import ./_themes-lib.nix { inherit lib; };
      mkPrompt = import ./_prompt-lib.nix { inherit pkgs lib; };
      prompts = lib.filterAttrs (_: p: p != null) (lib.mapAttrs
        (themeName: themeDir: mkPrompt {
          inherit themeName;
          theme = import (themeDir + "/_theme.nix");
          baseSettings = config.programs.starship.settings;
        })
        (themeLib.themePackages cfg));
    in
    {
      config = lib.mkIf ((cfg.enable or false) && config.programs.starship.enable) {
        xdg.configFile = lib.mapAttrs'
          (themeName: p: lib.nameValuePair "rice/prompt/${themeName}.fish" { source = p.fish; })
          prompts;
        programs.fish.interactiveShellInit = lib.mkBefore ''
          if set -q __rice_active[1]
              and test -r ${config.xdg.configHome}/rice/prompt/$__rice_active.fish
              source ${config.xdg.configHome}/rice/prompt/$__rice_active.fish
          end
        '';
      };
    };
}
