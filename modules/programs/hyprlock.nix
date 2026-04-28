{ inputs, ... }: {
  flake.homeModules.programs-hyprlock =
    { osConfig
    , config
    , pkgs
    , lib
    , ...
    }:
    let
      inherit (osConfig.environment.desktop.theme) wallpaper;
      c = config.theme.colors;
      s = config.theme.style;
      fmt = import ../themes/_fmt.nix lib;
      cfg = config.program.hyprlock;
      accent = c.${s.accentPrimary};

      statusColors = {
        check_color = fmt.rgba c.green "1.0";
        fail_color = fmt.rgba c.red "1.0";
        bothlock_color = fmt.rgba c.yellow "1.0";
        capslock_color = fmt.rgba c.peach "1.0";
        numlock_color = fmt.rgba c.sky "1.0";
      };
    in
    {
      options.program.hyprlock = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable hyprlock";
        };

        defaultMonitor = lib.mkOption {
          type = lib.types.str;
          default = "";
          description = "Monitor to show lock UI on. Set per-host in _home.nix. The lock-screen script overrides this at runtime.";
        };
      };

      config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
        programs.hyprlock = {
          enable = true;
          package = inputs.hyprlock.packages.${pkgs.stdenv.hostPlatform.system}.hyprlock;

          settings = {
            general = {
              immediate_render = true;
              hide_cursor = false;
            };

            background = [
              {
                monitor = "";
                path = "${wallpaper}";
                blur_passes = 2;
                contrast = 0.9;
                brightness = 0.8;
                vibrancy = 0.2;
                vibrancy_darkness = 0.0;
              }
            ];

            "input-field" = [
              ({
                monitor = cfg.defaultMonitor;
                size = "280, 50";
                outline_thickness = s.borderWidth;
                dots_size = 0.16;
                dots_spacing = 0.3;
                dots_center = true;
                outer_color = fmt.rgba accent "${toString s.opacityLockscreen}";
                inner_color = fmt.rgba c.surface0 "${toString s.opacityLockscreen}";
                font_color = fmt.rgba c.text "1.0";
                fade_on_empty = false;
                placeholder_text = "hunter2";
                hide_input = false;
                rounding = s.roundingSmall;
                position = "0, 40";
                halign = "center";
                valign = "bottom";
              } // statusColors)
            ];

            label = [
              # ── Clock (hero element, center-top) ──
              {
                monitor = cfg.defaultMonitor;
                text = "$TIME";
                color = fmt.rgba accent "1.0";
                font_size = s.fontSizeLockTime;
                font_family = s.fontMono;
                position = "0, 120";
                halign = "center";
                valign = "center";
              }
              # ── Date (below clock) ──
              {
                monitor = cfg.defaultMonitor;
                text = "cmd[update:60000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 date +\"%A, %d. %B\"";
                color = fmt.rgba c.lavender "0.9";
                font_size = s.fontSizeLockDate;
                font_family = s.fontMono;
                position = "0, 20";
                halign = "center";
                valign = "center";
              }
              # ── Greeting (subtle, above input) ──
              {
                monitor = cfg.defaultMonitor;
                text = "When the issue is labeled \"Bra for nybegynnere\" ༼ ༎ຶ ᆺ ༎ຶ༽";
                color = fmt.rgba c.subtext1 "0.5";
                font_size = s.fontSizeLockQuote;
                font_family = s.fontMono;
                position = "0, -60";
                halign = "center";
                valign = "center";
              }
            ];
          };
        };
      };
    };
}
