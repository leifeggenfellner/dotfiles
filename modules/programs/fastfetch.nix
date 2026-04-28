_: {
  flake.homeModules.programs-fastfetch =
    { pkgs, lib, osConfig, config, ... }:
    let
      c = config.theme.colors;
      s = config.theme.style;
      fmt = import ../themes/_fmt.nix lib;
      # Map semantic color names → ANSI SGR codes (matching foot/termKeys palette)
      # Using palette indices means OSC 4 overrides from theme-switcher take effect
      nameToSgr = {
        base = 30;
        red = 31;
        green = 32;
        yellow = 33;
        blue = 34;
        mauve = 35;
        teal = 36;
        text = 37;
        surface1 = 90;
      };
      # Palette-indexed escape with real ESC byte (for fastfetch JSON config)
      paletteAnsi = name:
        if nameToSgr ? ${name}
        then fmt.sgr nameToSgr.${name}
        else fmt.ansiJson c.${name};
      # Palette-indexed escape for fish shell (\x1b style)
      paletteFishAnsi = name:
        if nameToSgr ? ${name}
        then "\\x1b[${toString nameToSgr.${name}}m"
        else fmt.ansi c.${name};
      accent1 = paletteFishAnsi s.accentPrimary;
      reset = "\\x1b[0m";
      artFile = ./fastfetch/oshuwan.txt;
      # Fastfetch color constants — palette-indexed for live theme switching
      c1 = paletteAnsi s.accentPrimary; # accent
      c2 = paletteAnsi s.accentSecondary; # accent2
      c3 = paletteAnsi "surface1"; # dim
      cw = fmt.sgr 37; # white
    in
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home.packages = [ pkgs.fastfetch ];
        programs.fish.functions.fish_greeting = ''
          # Apply cached theme colors for new terminals opened after a theme switch
          if test -f ~/.cache/theme-term-colors
            command cat ~/.cache/theme-term-colors
          end
          echo -ne '${accent1}'
          command cat ${artFile}
          echo -ne '${reset}'
          echo ""
          fastfetch
        '';
        xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo.type = "none";
          display = {
            separator = "";
            key.paddingLeft = 2;
            color = {
              output = "white";
            };
            constants = [ cw c1 c2 c3 ];
          };
          modules = [
            "break"
            {
              type = "custom";
              key = "╭────────────────────────────────────╮";
            }
            {
              type = "command";
              key = "│ {$2}{$1}  user  ";
              text = "printf '%s@%s' \"$USER\" \"$(hostname)\"";
              format = " {$4}▐{$1} {$3}{>22}{$1} │";
            }
            {
              type = "os";
              key = "│ {$2}󱄅{$1}  distro";
              format = " {$4}▐{$1} {$2}{pretty-name>22}{$1} │";
            }
            {
              type = "kernel";
              key = "│ {$2}{$1}  kernel";
              format = " {$4}▐{$1} {$2}{release>22}{$1} │";
            }
            {
              type = "command";
              key = "│ {$2}󱎫{$1}  uptime";
              text = "uptime -p | cut -d ' ' -f 2-";
              format = " {$4}▐{$1} {$2}{>22}{$1} │";
            }
            {
              type = "shell";
              key = "│ {$2}{$1}  shell ";
              format = " {$4}▐{$1} {$2}{pretty-name>22}{$1} │";
            }
            {
              type = "command";
              key = "│ {$2}󰍛{$1}  mem   ";
              text = "free -m | awk 'NR==2{printf \"%.1f GiB / %.1f GiB\",$3/1024,$2/1024}'";
              format = " {$4}▐{$1} {$2}{>22}{$1} │";
            }
            {
              type = "packages";
              key = "│ {$2}{$1}  pkgs  ";
              format = " {$4}▐{$1} {$2}{all>22}{$1} │";
            }
            {
              type = "custom";
              key = "╰────────────────────────────────────╯";
            }
            "break"
            {
              type = "colors";
              paddingLeft = 4;
              symbol = "circle";
              block = {
                range = [ 0 15 ];
                width = 3;
              };
            }
            "break"
          ];
        };
      };
    };
}
