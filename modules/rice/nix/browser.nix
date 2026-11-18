# Zen dressed by the rice (D-060), for the configured theme: its chrome
# stylesheet and the new-tab page are generated at rebuild and wired in
# through Zen's autoconfig. The page's live part is the feed the shell
# writes (modules/newtab). A theme with neither leaves Zen stock.
_: {
  flake.homeModules.rice-browser =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      themeLib = import ./_themes-lib.nix { inherit lib; };
      theme = import (themeLib.themePackage cfg cfg.theme + "/_theme.nix");
      generated = import ./_browser-lib.nix { inherit pkgs lib; } {
        inherit theme;
        feedPath = "${config.xdg.stateHome}/rice/newtab-feed.js";
        links = config.program.zen.newtabLinks;
      };
      newtabUrl = "file://${config.xdg.dataHome}/rice/newtab/index.html";
    in
    {
      config = lib.mkIf (cfg.enable or false) (lib.mkMerge [
        (lib.mkIf (generated.zenChrome != null) {
          # A user sheet beats the workspace colours Zen sets inline, and
          # needs no profile (whose directory name is random).
          program.zen.autoconfig = ''
            try {
              const sss = Cc["@mozilla.org/content/style-sheet-service;1"].getService(Ci.nsIStyleSheetService);
              const sheet = Services.io.newURI("file://${generated.zenChrome}");
              if (!sss.sheetRegistered(sheet, sss.USER_SHEET))
                sss.loadAndRegisterSheet(sheet, sss.USER_SHEET);
            } catch (e) {
              Cu.reportError(e);
            }
          '';
        })
        (lib.mkIf (generated.newtab != null) {
          xdg.dataFile."rice/newtab".source = generated.newtab;
          # Defaults only, so about:config still wins. Zen opens the URL bar
          # instead of a page on Ctrl+T unless replace-newtab is off.
          program.zen.autoconfig = ''
            defaultPref("zen.urlbar.replace-newtab", false);
            defaultPref("browser.startup.homepage", "${newtabUrl}");
            try {
              const { AboutNewTab } = ChromeUtils.importESModule("resource:///modules/AboutNewTab.sys.mjs");
              AboutNewTab.newTabURL = "${newtabUrl}";
            } catch (e) {
              Cu.reportError(e);
            }
          '';
        })
      ]);
    };
}
