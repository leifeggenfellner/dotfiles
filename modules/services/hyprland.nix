{ inputs, ... }:
{
  flake.nixosModules.services-hyprland =
    { lib, pkgs, config, ... }:
    {
      imports = [
        inputs.hyprland.nixosModules.default
      ];

      config = lib.mkIf (config.environment.desktop.windowManager == "hyprland") {
        environment = {
          systemPackages = [
            inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
          ];
          pathsToLink = [ "/share/icons" ];
          variables = {
            HYPRLAND_CONFIG = "/home/leif/.config/hypr/hyprland.lua";
            NIXOS_OZONE_WL = "1";
          };
        };

        programs = {
          hyprland = {
            enable = true;
            withUWSM = true;
            package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
            plugins = [ ];
          };

          fish.loginShellInit = ''
            if test (tty) = "/dev/tty1"
              exec Hyprland --config "$HOME/.config/hypr/hyprland.lua" &> /dev/null
            end
          '';
        };

        xdg.portal = {
          enable = true;
          xdgOpenUsePortal = true;
          config = {
            common.default = [ "gtk" ];
            hyprland.default = [
              "gtk"
              "hyprland"
            ];
          };
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
          ];
        };
      };
    };
}
