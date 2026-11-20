# Baseline group-bar chrome and window shadow (Hyprland's own
# defaults, made explicit). Imported by _settings.nix (the generated
# config) and by the rice Hyprland adapter, which re-applies them before
# a theme's chrome so switching to a theme without one restores them
# exactly (D-049, D-072).
{
  shadow = {
    enabled = true;
    range = 4;
    render_power = 3;
    color = "rgba(1a1a1aee)";
    offset = "0 0";
  };

  groupbar = {
    col = {
      active = "rgba(ffff0066)";
      inactive = "rgba(77770066)";
    };
    text_color = "rgb(ffffff)";
    text_color_inactive = "rgb(ffffff)";
    font_family = "";
  };
}
