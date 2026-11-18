{ inputs, ... }: {
  flake.homeModules.programs-spotify =
    { osConfig, pkgs, lib, ... }:
    {
      imports = [ inputs.spicetify-nix.homeManagerModules.spicetify ];

      config = lib.mkMerge [
        (lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
          home.persistence."/persist/" = {
            directories = [
              ".config/spotify"
              ".cache/spotify"
            ];
          };

          # Spotify patched by Spicetify so the rice can colour it (D-059).
          # The default theme with no scheme keeps Spotify's own look.
          programs.spicetify = {
            enable = true;
            theme = lib.mkDefault inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system}.themes.default;
          };
        })
        (lib.mkIf (osConfig.environment.desktop.windowManager == "gnome") {
          home.packages = [
            pkgs.spotify
          ];
        })
      ];
    };
}
