_: {
  flake.homeModules.programs-cava =
    { lib, config, osConfig, ... }:
    let
      c = config.theme.colors;
      fmt = import ../themes/_fmt.nix lib;
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.cava = {
          enable = true;
          settings = {
            input = {
              method = "pulse";
              source = "auto";
            };
            general = {
              framerate = 60;
              bar_width = 2;
              bar_spacing = 1;
            };
            smoothing = {
              noise_reduction = 77;
            };
            color = {
              gradient = 1;
              gradient_count = 6;
              gradient_color_1 = "'${fmt.hex c.blue}'";
              gradient_color_2 = "'${fmt.hex c.teal}'";
              gradient_color_3 = "'${fmt.hex c.mauve}'";
              gradient_color_4 = "'${fmt.hex c.rosewater}'";
              gradient_color_5 = "'${fmt.hex c.red}'";
              gradient_color_6 = "'${fmt.hex c.peach}'";
            };
          };
        };
      };
    };
}
