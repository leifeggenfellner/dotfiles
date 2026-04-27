_: {
  flake.homeModules.programs-cava =
    { lib, config, osConfig, ... }:
    let
      c = config.colorScheme.palette;
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        programs.cava = {
          enable = true;
          settings = {
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
              gradient_color_1 = "'#${c.base0D}'";
              gradient_color_2 = "'#${c.base0C}'";
              gradient_color_3 = "'#${c.base0E}'";
              gradient_color_4 = "'#${c.base06}'";
              gradient_color_5 = "'#${c.base08}'";
              gradient_color_6 = "'#${c.base09}'";
            };
          };
        };
      };
    };
}
