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
in
{
  programs.wofi = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
    enable = true;
    package = pkgs.wofi.overrideAttrs (oa: {
      patches =
        (oa.patches or [ ])
        ++ [
          ./wofi-run-shell.patch # Fix for https://todo.sr.ht/~scoopta/wofi/174
        ];
    });
    settings = {
      allow_images = true;
      width = "20%";
      hide_scroll = true;
      term = "foot";
      # Anti-jitter settings
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      parse_search = true;
      gtk_dark = true;
      # Layer shell settings to prevent background bleeding
      layer = "overlay";
    };
    style = ''
      * {
        font-family: ${commonSettings.font}, monospace;
        font-weight: bold;
        color: #${config.colorScheme.palette.base05};
        /* Enhanced anti-aliasing */
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        text-rendering: optimizeLegibility;
        box-sizing: border-box;
        outline: none;
        /* Force integer pixel positioning */
        image-rendering: crisp-edges;
      }

      #window {
        /* Even more solid background approach */
        background-color: #${config.colorScheme.palette.base00};
        border-radius: 18px; /* Slightly smaller radius for cleaner edges */
        border: 2px solid #${config.colorScheme.palette.base0D};

        /* Prevent subpixel positioning */
        position: relative;

        /* Enhanced clipping */
        overflow: hidden;

        /* Simplified shadow - no blur that might cause artifacts */
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);

        /* Force hardware acceleration for clean rendering */
        transform: translateZ(0);
        will-change: transform;

        /* Ensure crisp edges */
        shape-rendering: crispEdges;

        margin: 0;
        padding: 0;
      }

      /* Additional background layer for complete coverage */
      #window::after {
        content: "";
        position: absolute;
        top: 0;
        left: 0;
        right: 0;
        bottom: 0;
        background-color: #${config.colorScheme.palette.base00};
        border-radius: 16px; /* Slightly smaller than window */
        z-index: -1;
        pointer-events: none;
      }

      #input {
        border-radius: 12px; /* Further reduced for cleaner edges */
        margin: 12px;
        padding: 10px 16px;
        background-color: #${config.colorScheme.palette.base01};
        color: #${config.colorScheme.palette.base07};
        border: 1px solid #${config.colorScheme.palette.base02};
        min-height: 18px;
        box-sizing: border-box;

        /* Ensure crisp input field */
        image-rendering: crisp-edges;
      }

      #input:focus {
        border: 1px solid #${config.colorScheme.palette.base0D};
        box-shadow: 0 0 0 1px rgba(113, 156, 214, 0.3);
        outline: none;
      }

      #outer-box {
        font-weight: bold;
        font-size: ${commonSettings.fontsize}px;
        margin: 4px;
        padding: 8px;
        min-height: 100%;
        box-sizing: border-box;
      }

      #scroll {
        overflow-y: auto;
        overflow-x: hidden;
        /* Ensure scroll area doesn't interfere with edges */
        margin: 2px;
      }

      #text {
        color: #${config.colorScheme.palette.base05};
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        line-height: 1.4;
      }

      #entry {
        margin: 2px 12px;
        padding: 6px 10px;
        border-radius: 6px; /* Much smaller radius for cleaner look */
        border: none;
        background-color: transparent;
        min-height: 32px;
        box-sizing: border-box;
        display: flex;
        align-items: center;
        transition: all 0.12s ease-in-out;
      }

      #entry:selected {
        background-color: #${config.colorScheme.palette.base0D};
        color: #${config.colorScheme.palette.base00};
      }

      #entry:hover {
        background-color: #${config.colorScheme.palette.base02};
        color: #${config.colorScheme.palette.base06};
      }

      #entry img {
        margin-right: 8px;
        width: 18px;
        height: 18px;
        object-fit: contain;
        /* Ensure crisp icons */
        image-rendering: crisp-edges;
      }
    '';
  };
}
