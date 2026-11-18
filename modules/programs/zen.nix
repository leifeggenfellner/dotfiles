{ inputs, ... }: {
  flake.homeModules.programs-zen =
    { osConfig, config, pkgs, lib, ... }:
    let
      cfg = config.program.zen;
      zenPackages = inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system};
      unwrapped = zenPackages.zen-browser-unwrapped;

      # Wrapped like the flake's own package (wrapFirefox picks the FFmpeg
      # ABI from the Firefox version), plus our autoconfig.
      zen = pkgs.wrapFirefox (unwrapped // { version = unwrapped.firefoxVersion; }) {
        pname = "zen-browser";
        inherit (unwrapped) version;
        # Our autoconfig needs chrome privileges (Cc, Services); it is read
        # from the store, so the sandbox guards nothing here.
        extraAutoConfig = lib.optionalString (cfg.autoconfig != "") ''
          pref("general.config.sandbox_enabled", false);
        '';
        extraPrefs = cfg.autoconfig;
      };

      zenWithWayland = pkgs.symlinkJoin {
        name = "zen-browser-wayland";
        paths = [ zen ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/zen \
            --set MOZ_ENABLE_WAYLAND 1
        '';
      };
    in
    {
      options.program.zen = {
        autoconfig = lib.mkOption {
          type = lib.types.lines;
          default = "";
          description = ''
            JavaScript appended to Zen's autoconfig (mozilla.cfg), run with
            chrome privileges at startup: `defaultPref(...)`, `pref(...)`,
            and anything else autoconfig allows. The rice uses it for its
            chrome stylesheet and new-tab page (D-060).
          '';
        };
        newtabLinks = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              label = lib.mkOption { type = lib.types.str; };
              url = lib.mkOption { type = lib.types.str; };
            };
          });
          default = [
            { label = "GitHub"; url = "https://github.com"; }
            { label = "dotfiles"; url = "https://github.com/leifeggenfellner/dotfiles"; }
            { label = "Nix packages"; url = "https://search.nixos.org/packages"; }
            { label = "NixOS options"; url = "https://search.nixos.org/options"; }
            { label = "Home Manager options"; url = "https://home-manager-options.extranix.com"; }
            { label = "Noogle"; url = "https://noogle.dev"; }
          ];
          description = "Links on the rice's new-tab page, when the theme has one (D-060).";
        };
      };

      config.home = lib.mkIf osConfig.environment.desktop.enable {
        packages = [ zenWithWayland ];
        persistence."/persist/" = {
          directories = [
            ".zen"
          ];
        };
      };
    };
}
