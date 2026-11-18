_: {
  flake.homeModules.programs-discord =
    { osConfig, pkgs, lib, ... }:
    {
      config = lib.mkMerge [
        # Vesktop (Vencord built in) so the rice can theme it (D-059); with no
        # rice theme it keeps Discord's own look.
        (lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
          programs.vesktop = {
            enable = true;
            # Vencord writes these itself; ours are merged in at activation.
            mutableSettings = true;
            vencord.mutableSettings = true;
            vencord.settings.enabledThemes = lib.mkDefault [ ];
          };
          home.persistence."/persist/".directories = [ ".config/vesktop" ];
        })
        (lib.mkIf (osConfig.environment.desktop.enable && osConfig.environment.desktop.windowManager != "hyprland") {
          home = {
            packages = [ pkgs.discord ];
            persistence."/persist/".directories = [ ".config/discord" ];
          };
          xdg.configFile."discord/settings.json".text = ''
            {
              "SKIP_HOST_UPDATE": true
            }
          '';
        })
      ];
    };
}
