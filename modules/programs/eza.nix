_: {
  flake.homeModules.programs-eza =
    { lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.eza = {
          enable = true;
          enableFishIntegration = true;
          icons = "auto";
          git = true;
          extraOptions = [
            "--group-directories-first"
            "--header"
          ];
        };
      };
    };
}
