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
      /* The magic fix - reset everything that causes bleeding */
      * {
        background: none;
        border: none;
        font-size: ${commonSettings.fontsize}px;
        font-family: ${commonSettings.font}, monospace;
        font-weight: bold;
        color: #${config.colorScheme.palette.base05};
        /* Enhanced anti-aliasing */
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        text-rendering: optimizeLegibility;
        box-sizing: border-box;
        outline: none;
      }

      #window {
        /* Apply alpha 0.9 to background as suggested */
        background-color: rgba(${
          let
            hex = config.colorScheme.palette.base00;
            r = toString (lib.trivial.fromHexString (builtins.substring 0 2 hex));
            g = toString (lib.trivial.fromHexString (builtins.substring 2 2 hex));
            b = toString (lib.trivial.fromHexString (builtins.substring 4 2 hex));
          in "${r}, ${g}, ${b}"
        }, 0.9);

        border-radius: 18px;
        border: 2px solid #${config.colorScheme.palette.base0E}; /* Changed from base0D to base0E (magenta) */

        /* Clean, simple styling */
        margin: 0;
        padding: 0;
        overflow: hidden;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
      }

      #input {
        border-radius: 12px;
        margin: 12px;
        padding: 10px 16px;
        background-color: #${config.colorScheme.palette.base01};
        color: #${config.colorScheme.palette.base07};
        border: 1px solid #${config.colorScheme.palette.base02};
        min-height: 18px;
        box-sizing: border-box;
      }

      #input:focus {
        border: 1px solid #${config.colorScheme.palette.base0E}; /* Changed from base0D to base0E (magenta) */
        box-shadow: 0 0 0 1px rgba(180, 142, 173, 0.3); /* Changed to magenta rgba (B48EAD) */
        outline: none;
      }

      #outer-box {
        margin: 4px;
        padding: 8px;
        min-height: 100%;
        box-sizing: border-box;
      }

      #scroll {
        overflow-y: auto;
        overflow-x: hidden;
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
        border-radius: 6px;
        background-color: transparent;
        min-height: 32px;
        box-sizing: border-box;
        display: flex;
        align-items: center;
        transition: all 0.12s ease-in-out;
      }

      #entry:selected {
        background-color: #${config.colorScheme.palette.base0E}; /* Changed from base0D to base0E (magenta) */
        color: #${config.colorScheme.palette.base00}; /* Dark text on magenta background for readability */
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
      }
    '';
  };
}
