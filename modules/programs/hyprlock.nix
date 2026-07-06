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

      # Themeable hyprlang variables (D-020): defaults baked here from
      # the legacy bridge; lock-screen overrides the definition lines
      # at lock time from the active rice manifest. Widgets reference
      # $rice_* only. HM emits "$"-prefixed keys before all sections
      # (importantPrefixes), so variable-before-use ordering holds.
      vars = import ./_hyprlock-vars.nix {
        inherit (s) accentPrimary opacityLockscreen;
      };
      varDefaults =
        lib.mapAttrs' (n: v: lib.nameValuePair ("$" + n) (fmt.rgba c.${v.key} (toString v.alpha))) vars.colors
        // lib.mapAttrs' (n: _: lib.nameValuePair ("$" + n) s.fontMono) vars.fonts;

      statusColors = {
        check_color = "$rice_ok";
        fail_color = "$rice_danger";
        bothlock_color = "$rice_warn";
        capslock_color = "$rice_caps";
        numlock_color = "$rice_num";
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

          settings = varDefaults // {
            general = {
              immediate_render = true;
              hide_cursor = false;
            };

            background = [
              {
                monitor = "";
                path = "${wallpaper}";
                color = "$rice_base";
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
                outer_color = "$rice_accent";
                inner_color = "$rice_surface";
                font_color = "$rice_text";
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
                color = "$rice_accent_solid";
                font_size = s.fontSizeLockTime;
                font_family = "$rice_font_display";
                position = "0, 120";
                halign = "center";
                valign = "center";
              }
              # ── Date (below clock) ──
              {
                monitor = cfg.defaultMonitor;
                text = "cmd[update:60000] TZ='Europe/Oslo' LC_TIME=nb_NO.UTF-8 date +\"%A, %d. %B\"";
                color = "$rice_date";
                font_size = s.fontSizeLockDate;
                font_family = "$rice_font_display";
                position = "0, 20";
                halign = "center";
                valign = "center";
              }
              # ── Greeting (subtle, above input) ──
              {
                monitor = cfg.defaultMonitor;
                text = "When the issue is labeled \"Bra for nybegynnere\" ༼ ༎ຶ ᆺ ༎ຶ༽";
                color = "$rice_quote";
                font_size = s.fontSizeLockQuote;
                font_family = "$rice_font_mono";
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
