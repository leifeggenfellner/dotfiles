_: {
  flake.homeModules.programs-alacritty =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      cfg = config.program.alacritty;
      c = config.theme.colors;
      s = config.theme.style;
      fmt = import ../themes/_fmt.nix lib;
    in
    {
      options.program.alacritty = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable alacritty terminal";
        };
      };

      config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
        programs.alacritty = {
          enable = true;
          settings = {
            bell = {
              animation = "EaseOutExpo";
              duration = 5;
              color = fmt.hex c.text;
            };
            colors = {
              primary = {
                background = fmt.hex c.base;
                foreground = fmt.hex c.text;
              };
              cursor = {
                text = fmt.hex c.rosewater;
                cursor = fmt.hex c.text;
              };
              vi_mode_cursor = {
                text = fmt.hex c.rosewater;
                cursor = fmt.hex c.teal;
              };
              search = {
                matches = {
                  foreground = fmt.hex c.rosewater;
                  background = fmt.hex c.surface1;
                };
                focused_match = {
                  foreground = fmt.hex c.rosewater;
                  background = fmt.hex c.green;
                };
              };
              footer_bar = {
                foreground = fmt.hex c.rosewater;
                background = fmt.hex c.mantle;
              };
              hints = {
                start = {
                  foreground = fmt.hex c.rosewater;
                  background = fmt.hex c.peach;
                };
                end = {
                  foreground = fmt.hex c.rosewater;
                  background = fmt.hex c.mantle;
                };
              };
              normal = {
                black = fmt.hex c.base;
                red = fmt.hex c.red;
                green = fmt.hex c.green;
                yellow = fmt.hex c.yellow;
                blue = fmt.hex c.blue;
                magenta = fmt.hex c.mauve;
                cyan = fmt.hex c.teal;
                white = fmt.hex c.text;
              };
              bright = {
                black = fmt.hex c.mantle;
                red = fmt.hex c.red;
                green = fmt.hex c.green;
                yellow = fmt.hex c.yellow;
                blue = fmt.hex c.blue;
                magenta = fmt.hex c.mauve;
                cyan = fmt.hex c.teal;
                white = fmt.hex c.lavender;
              };
              dim = {
                black = fmt.hex c.surface0;
                red = fmt.hex c.red;
                green = fmt.hex c.green;
                yellow = fmt.hex c.yellow;
                blue = fmt.hex c.blue;
                magenta = fmt.hex c.mauve;
                cyan = fmt.hex c.teal;
                white = fmt.hex c.surface2;
              };
            };
            font = {
              normal = {
                family = s.fontMono;
                style = "Medium";
              };
              bold = {
                family = s.fontMono;
                style = "Bold";
              };
              italic = {
                family = s.fontMono;
                style = "Italic";
              };
              bold_italic = {
                family = s.fontMono;
                style = "Bold Italic";
              };
              size = s.fontSizeSmall;
            };
            hints.enabled = [
              {
                regex = ''(mailto:|gemini:|gopher:|https:|http:|news:|file:|git:|ssh:|ftp:)[^\u0000-\u001F\u007F-\u009F<>"\\s{-}\\^⟨⟩`]+'';
                command = "${pkgs.mimeo}/bin/mimeo";
                post_processing = true;
                mouse.enabled = true;
              }
            ];
            selection.save_to_clipboard = true;
            terminal.shell.program = "${pkgs.fish}/bin/fish";
            window = {
              dimensions = {
                columns = 154;
                lines = 37;
              };
              decorations = "none";
              opacity = s.opacityTerminal;
              padding = {
                x = 5;
                y = 5;
              };
            };
          };
        };
      };
    };
}
