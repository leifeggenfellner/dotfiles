_: {
  flake.homeModules.programs-wofi =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      s = config.theme.style;

      # Named palette + format helpers
      c = config.theme.colors;
      fmt = import ../../themes/_fmt.nix lib;
    in
    {
      programs.wofi = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        enable = true;
        package = pkgs.wofi.overrideAttrs (oa: {
          patches =
            (oa.patches or [ ])
            ++ [
              ./wofi-run-shell.patch
            ];
        });
        settings = {
          allow_images = true;
          width = "20%";
          hide_scroll = true;
          term = "foot";
          filter_rate = 100;
          allow_markup = true;
          no_actions = true;
          halign = "fill";
          orientation = "vertical";
          content_halign = "fill";
          insensitive = true;
          parse_search = true;
          gtk_dark = true;
          layer = "overlay";
          cache_file = "/tmp/wofi-cache";
          show = "drun";
          prompt = "Search...";
        };
        style = ''
          /* Global reset and base styles */
          * {
            background: none;
            border: none;
            margin: 0;
            padding: 0;
            font-family: ${s.fontMono}, monospace;
            font-size: ${toString s.fontSizeNormal}px;
            font-weight: bold;
            color: ${fmt.hex c.text};
            outline: none;
            box-sizing: border-box;
          }

          /* Main window */
          #window {
            background-color: ${fmt.rgba c.base (toString s.opacityPopups)};
            border: ${toString s.borderWidth}px solid ${fmt.hex c.mauve};
            border-radius: ${toString s.rounding}px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
            overflow: hidden;
          }

          /* Search input */
          #input {
            margin: 12px;
            padding: 10px 16px;
            border-radius: ${toString s.roundingSmall}px;
            background-color: ${fmt.hex c.mantle};
            color: ${fmt.hex c.lavender};
            border: 1px solid ${fmt.hex c.surface0};
            transition: border-color 0.2s ease;
          }

          #input:focus {
            border-color: ${fmt.hex c.mauve};
            box-shadow: 0 0 0 1px ${fmt.rgba c.mauve "0.3"};
          }

          #input > *:not(:last-child) {
            margin-right: 1rem;
          }

          /* Container boxes */
          #outer-box {
            margin: 4px;
            padding: 8px;
          }

          #scroll {
            overflow-y: auto;
            overflow-x: hidden;
            margin: 2px;
          }

          /* Entry items */
          #entry {
            margin: 2px 12px;
            padding: 6px 10px;
            border-radius: ${toString (s.roundingSmall - 6)}px;
            min-height: 32px;
            transition: background-color 0.12s ease;
          }

          #entry:hover {
            background-color: ${fmt.hex c.surface0};
            color: ${fmt.hex c.rosewater};
          }

          #entry:selected {
            background-color: ${fmt.hex c.mauve};
          }

          /* Icons and text */
          #entry img {
            width: 18px;
            height: 18px;
            object-fit: contain;
          }

          #text {
            color: inherit;
            line-height: 1.4;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
            padding-left: 12px;
          }

          #text:selected {
            color: ${fmt.hex c.base};
          }
        '';
      };
    };
}
