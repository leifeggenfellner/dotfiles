_: {
  flake.nixosModules.config-theme =
    { lib, config, ... }:
    let
      palettes = import ../themes/_palettes.nix;
      schemeNames = builtins.attrNames palettes;
      themeLib = import ../rice/nix/_themes-lib.nix { inherit lib; };
      riceThemePackages = if (config.rice.enable or false) then themeLib.themePackages config.rice else { };
      activeScheme = import ../themes/_active-scheme.nix;
      defaults = import ../themes/_style.nix;
      t = lib.types;
      mkS = type: key: description:
        lib.mkOption { inherit type description; default = defaults.${key}; };
    in
    {
      options.environment.desktop.theme = {
        enable = lib.mkOption {
          type = t.bool;
          default = true;
          description = "Enable wallpaper configuration";
        };

        scheme = lib.mkOption {
          type = t.str;
          default = activeScheme;
          description = "Active color scheme name. Static schemes: ${builtins.concatStringsSep ", " schemeNames}; rice theme packages may add more.";
        };

        wallpaper = lib.mkOption {
          type = t.str;
          default = "/home/leif/Pictures/wallpapers/catppuccin/os/nixos_waves.png";
          example = "/home/user/Pictures/wallpaper.png";
          description = "Path to the wallpaper image file";
        };

        style = {
          # ── Geometry ────────────────────────────────────────────────
          rounding = mkS t.int "rounding" "Default corner radius (px)";
          roundingSmall = mkS t.int "rounding_small" "Smaller radius for inner widgets";
          gapsInner = mkS t.int "gaps_inner" "Gap between tiled windows (px)";
          gapsOuter = mkS t.int "gaps_outer" "Gap between windows and screen edge (px)";
          borderWidth = mkS t.int "border_width" "Border thickness (px)";

          # ── Opacity ─────────────────────────────────────────────────
          opacityActive = mkS t.float "opacity_active" "Active window opacity";
          opacityInactive = mkS t.float "opacity_inactive" "Inactive window opacity";
          opacityPopups = mkS t.float "opacity_popups" "Floating UI opacity (wofi, menus)";
          opacityBar = mkS t.float "opacity_bar" "Waybar / EWW bar opacity";
          opacityTerminal = mkS t.float "opacity_terminal" "Terminal background opacity";
          opacityLockscreen = mkS t.float "opacity_lockscreen" "Lock-screen overlay opacity";

          # ── Blur ────────────────────────────────────────────────────
          blurSize = mkS t.int "blur_size" "Blur kernel size";
          blurPasses = mkS t.int "blur_passes" "Number of blur passes";
          blurContrast = mkS t.float "blur_contrast" "Blur contrast multiplier";
          blurBrightness = mkS t.float "blur_brightness" "Blur brightness multiplier";
          blurNoise = mkS t.float "blur_noise" "Blur noise amount";

          # ── Fonts ───────────────────────────────────────────────────
          fontMono = mkS t.str "font_mono" "Monospace font for terminals, bars, widgets";
          fontSans = mkS t.str "font_sans" "Sans-serif font for GTK/Qt";
          fontSizeSmall = mkS t.int "font_size_small" "Small text size (terminal)";
          fontSizeNormal = mkS t.int "font_size_normal" "Normal UI text size";
          fontSizeBar = mkS t.int "font_size_bar" "Status bar font size";
          fontSizeBarIcon = mkS t.int "font_size_bar_icon" "Status bar icon size";
          fontSizeNotification = mkS t.int "font_size_notification" "Notification body size";
          fontSizeLockTime = mkS t.int "font_size_lock_time" "Lock-screen clock size";
          fontSizeLockDate = mkS t.int "font_size_lock_date" "Lock-screen date size";
          fontSizeLockQuote = mkS t.int "font_size_lock_quote" "Lock-screen quote size";

          # ── Cursor ──────────────────────────────────────────────────
          cursorName = mkS t.str "cursor_name" "Cursor theme name";
          cursorSize = mkS t.int "cursor_size" "Cursor size (px)";

          # ── Accent mapping (palette key names) ──────────────────────
          accentPrimary = mkS t.str "accent_primary" "Primary accent color (palette key)";
          accentSecondary = mkS t.str "accent_secondary" "Secondary accent color (palette key)";
          accentTertiary = mkS t.str "accent_tertiary" "Tertiary accent color (palette key)";

          # ── Animation bezier curves ─────────────────────────────────
          bezierWind = mkS t.str "bezier_wind" "Default snappy curve";
          bezierWinIn = mkS t.str "bezier_winIn" "Bouncy entrance curve";
          bezierWinOut = mkS t.str "bezier_winOut" "Anticipation exit curve";
          bezierLiner = mkS t.str "bezier_liner" "Linear curve";
          bezierOvershot = mkS t.str "bezier_overshot" "Overshoot for workspace transitions";

          # ── Animation speeds ────────────────────────────────────────
          speedWindowOpen = mkS t.int "speed_window_open" "Window open/in speed";
          speedWindowClose = mkS t.int "speed_window_close" "Window close/out speed";
          speedWindowMove = mkS t.int "speed_window_move" "Window move speed";
          speedBorder = mkS t.int "speed_border" "Border color transition speed";
          speedBorderAngle = mkS t.int "speed_border_angle" "Border angle rotation speed";
          speedFade = mkS t.int "speed_fade" "Fade speed";
          speedLayer = mkS t.int "speed_layer" "Layer open speed";
          speedLayerIn = mkS t.int "speed_layer_in" "Layer entrance speed";
          speedLayerOut = mkS t.int "speed_layer_out" "Layer exit speed";
          speedWorkspace = mkS t.int "speed_workspace" "Workspace switch speed";
          speedSpecialWorkspace = mkS t.int "speed_special_workspace" "Special workspace speed";

          # ── Waybar ──────────────────────────────────────────────────
          barHeight = mkS t.int "bar_height" "Waybar height (px)";
          barMarginTop = mkS t.int "bar_margin_top" "Top margin";
          barMarginHorizontal = mkS t.int "bar_margin_horizontal" "Left/right margin";
          barSpacing = mkS t.int "bar_spacing" "Module spacing";
          barPosition = mkS t.str "bar_position" "Bar position (top/bottom)";
        };
      };

      config.assertions = [
        {
          assertion =
            let scheme = config.environment.desktop.theme.scheme; in
            lib.hasAttr scheme palettes || lib.hasAttr scheme riceThemePackages;
          message = "environment.desktop.theme.scheme '${config.environment.desktop.theme.scheme}' is neither a static palette nor a configured rice theme package.";
        }
      ];
    };
}
