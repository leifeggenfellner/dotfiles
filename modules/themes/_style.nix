# Default visual style values — pure data, no module logic.
# Imported by config/theme.nix (NixOS options) and themes/default.nix (HM bridge).
# To support rice profiles, override `environment.desktop.theme.style.*` per-host.
{
  # ── Geometry ──────────────────────────────────────────────────────
  rounding = 16;
  rounding_small = 12;
  gaps_inner = 7;
  gaps_outer = 7;
  border_width = 2;

  # ── Opacity ────────────────────────────────────────────────────────
  opacity_active = 1.0;
  opacity_inactive = 0.95;
  opacity_popups = 0.9;
  opacity_bar = 0.8;
  opacity_terminal = 0.9;
  opacity_lockscreen = 0.8;

  # ── Blur ───────────────────────────────────────────────────────────
  blur_size = 8;
  blur_passes = 4;
  blur_contrast = 1.1;
  blur_brightness = 1.0;
  blur_noise = 0.02;

  # ── Fonts ──────────────────────────────────────────────────────────
  font_mono = "RobotoMono Nerd Font";
  font_sans = "Inter";
  font_size_small = 10;
  font_size_normal = 12;
  font_size_bar = 14;
  font_size_bar_icon = 17;
  font_size_notification = 13;
  font_size_lock_time = 120;
  font_size_lock_date = 28;
  font_size_lock_quote = 20;

  # ── Cursor ─────────────────────────────────────────────────────────
  cursor_name = "capitaine-cursors-white";
  cursor_size = 16;

  # ── Accent mapping (palette key names) ─────────────────────────────
  accent_primary = "mauve";
  accent_secondary = "blue";
  accent_tertiary = "sapphire";

  # ── Animation bezier curves ────────────────────────────────────────
  bezier_wind = "0.05, 0.9, 0.1, 1.05";
  bezier_winIn = "0.1, 1.1, 0.1, 1.1";
  bezier_winOut = "0.3, -0.3, 0, 1";
  bezier_liner = "1, 1, 1, 1";
  bezier_overshot = "0.13, 0.99, 0.29, 1.1";

  # ── Animation speeds ───────────────────────────────────────────────
  speed_window_open = 6;
  speed_window_close = 5;
  speed_window_move = 5;
  speed_border = 10;
  speed_border_angle = 60;
  speed_fade = 10;
  speed_layer = 4;
  speed_layer_in = 4;
  speed_layer_out = 3;
  speed_workspace = 6;
  speed_special_workspace = 6;

  # ── Waybar ─────────────────────────────────────────────────────────
  bar_height = 36;
  bar_margin_top = 6;
  bar_margin_horizontal = 8;
  bar_spacing = 8;
  bar_position = "top";
}

