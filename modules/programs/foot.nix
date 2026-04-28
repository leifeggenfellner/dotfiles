_: {
  flake.homeModules.programs-foot =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      c = config.theme.colors;
      s = config.theme.style;
      cfg = config.program.foot;
    in
    {

      options.program.foot = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable foot terminal";
        };
      };
      config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
        programs.foot = {
          enable = true;
          settings = {
            main = {
              font = "${s.fontMono}:size=${toString s.fontSizeSmall}";
              horizontal-letter-offset = 0;
              vertical-letter-offset = 0;
              pad = "5x5 center";
              selection-target = "clipboard";
            };

            bell = {
              urgent = "yes";
              notify = "yes";
            };

            desktop-notifications = {
              command = "${lib.getExe pkgs.libnotify} -a \${app-id} -i \${app-id} \${title} \${body}";
            };

            scrollback = {
              lines = 10000;
              multiplier = 3;
              indicator-position = "relative";
              indicator-format = "line";
            };

            url = {
              launch = "${pkgs.mimeo}/bin/mimeo \${url}";
            };

            cursor = {
              style = "beam";
              beam-thickness = 1;
            };

            colors-dark = {
              alpha = s.opacityTerminal;
              foreground = c.text;
              background = c.base;
              regular0 = c.base; # black
              regular1 = c.red; # red
              regular2 = c.green; # green
              regular3 = c.yellow; # yellow
              regular4 = c.blue; # blue
              regular5 = c.mauve; # magenta
              regular6 = c.teal; # cyan
              regular7 = c.text; # white
              bright0 = c.surface1; # bright black
              bright1 = c.red; # bright red
              bright2 = c.green; # bright green
              bright3 = c.yellow; # bright yellow
              bright4 = c.blue; # bright blue
              bright5 = c.mauve; # bright magenta
              bright6 = c.teal; # bright cyan
              bright7 = c.lavender; # bright white
            };
          };
        };
      };
    };
}
