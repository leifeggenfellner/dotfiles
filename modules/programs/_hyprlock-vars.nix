# Themeable hyprlock variables (D-020). Single source of truth shared
# by the HM hyprlock config (rebuild-time defaults from theme.colors)
# and the lock-screen script (lock-time overrides from the active rice
# manifest). `key` is a legacy-palette key — valid against both
# config.theme.colors and a manifest's .palette.legacy.
{ accentPrimary, opacityLockscreen }:
{
  colors = {
    rice_accent = { key = accentPrimary; alpha = opacityLockscreen; };
    rice_accent_solid = { key = accentPrimary; alpha = 1.0; };
    rice_base = { key = "base"; alpha = 1.0; };
    rice_surface = { key = "surface0"; alpha = opacityLockscreen; };
    rice_text = { key = "text"; alpha = 1.0; };
    rice_date = { key = "lavender"; alpha = 0.9; };
    rice_quote = { key = "subtext1"; alpha = 0.5; };
    rice_ok = { key = "green"; alpha = 1.0; };
    rice_danger = { key = "red"; alpha = 1.0; };
    rice_warn = { key = "yellow"; alpha = 1.0; };
    rice_caps = { key = "peach"; alpha = 1.0; };
    rice_num = { key = "sky"; alpha = 1.0; };
  };
  # `family` indexes the manifest's .tokens.typography.families.
  fonts = {
    rice_font_display = { family = "display"; };
    rice_font_mono = { family = "mono"; };
  };
}
