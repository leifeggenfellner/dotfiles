{ osConfig
, config
, pkgs
, lib
, ...
}:
let
  commonSettings = {
    font = "RobotoMono Nerd Font";
    fontsize = "12";
    cursor = "Numix-Cursor";
  };

  # Extract colors for better readability
  colors = config.colorScheme.palette;

  # Calculate RGB values for alpha background
  backgroundRgb =
    let
      hex = colors.base00;
      r = toString (lib.trivial.fromHexString (builtins.substring 0 2 hex));
      g = toString (lib.trivial.fromHexString (builtins.substring 2 2 hex));
      b = toString (lib.trivial.fromHexString (builtins.substring 4 2 hex));
    in
    "${r}, ${g}, ${b}";
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
        font-family: ${commonSettings.font}, monospace;
        font-size: ${commonSettings.fontsize}px;
        font-weight: bold;
        color: #${colors.base05};
        outline: none;
        box-sizing: border-box;
      }

      /* Main window */
      #window {
        background-color: rgba(${backgroundRgb}, 0.9);
        border: 2px solid #${colors.base0E};
        border-radius: 18px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
        overflow: hidden;
      }

      /* Search input */
      #input {
        margin: 12px;
        padding: 10px 16px;
        border-radius: 12px;
        background-color: #${colors.base01};
        color: #${colors.base07};
        border: 1px solid #${colors.base02};
        transition: border-color 0.2s ease;
      }

      #input:focus {
        border-color: #${colors.base0E};
        box-shadow: 0 0 0 1px rgba(203, 166, 247, 0.3);
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
        border-radius: 6px;
        min-height: 32px;
        transition: background-color 0.12s ease;
      }

      #entry:hover {
        background-color: #${colors.base02};
        color: #${colors.base06};
      }

      #entry:selected {
        background-color: #${colors.base0E};
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
        color: #${colors.base00};
      }
    '';
  };
}
