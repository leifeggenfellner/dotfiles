# Builds one NixOS/Home Manager specialisation per packaged rice
# theme (D-034). The base system remains the configured
# `rice.theme`; generated entries provide intentional full-chrome
# switches for GTK/Qt/HM-derived theme state.
_: {
  flake.nixosModules.rice-specialisations =
    { lib, config, ... }:
    let
      cfg = config.rice;
      themeLib = import ./_themes-lib.nix { inherit lib; };
      packagedThemes = themeLib.themeNames cfg;
      configuredThemes = if cfg.specialisations.themes == [ ] then packagedThemes else cfg.specialisations.themes;
      themes = lib.unique configuredThemes;
      specialisationName = theme: "${cfg.specialisations.prefix}${theme}";
    in
    {
      config = lib.mkIf (cfg.enable && cfg.specialisations.enable) {
        assertions = [
          {
            assertion = themes != [ ];
            message = "rice.specialisations.themes must contain at least one theme when rice specialisations are enabled.";
          }
        ];

        specialisation = lib.listToAttrs (map
          (theme: {
            name = specialisationName theme;
            value = {
              inheritParentConfig = true;
              configuration = {
                rice.theme = lib.mkForce theme;
                rice.specialisations.enable = lib.mkForce false;
                environment.desktop.theme.scheme = lib.mkForce theme;
                system.nixos.tags = lib.mkAfter [ (specialisationName theme) ];
              };
            };
          })
          themes);
      };
    };
}
