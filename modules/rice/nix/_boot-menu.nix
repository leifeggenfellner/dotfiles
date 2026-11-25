# Limine boot-menu style for a rice theme (D-092), built from the
# theme's `integration.boot.menu` data and colour tokens at rebuild time:
#   wallpaper  JPEG/PNG behind the menu, darkened here so text reads
#   branding   title at the top of the menu
# Returns an attrset for `boot.loader.limine.style`. Limine draws the
# selected entry in reverse video, so its bar is the terminal
# foreground: there is no separate highlight colour to set.
{ pkgs, lib }:
{ themeName, theme }:
let
  menu = theme.integration.boot.menu;
  colors = theme.tokens.colors;
  hex = c: builtins.substring 1 6 c;
  console = import ./_console-palette.nix { inherit lib; } theme.palette.legacy;

  # Cropped to 16:10 at 1920 wide (Limine stretches it to the screen)
  # and dimmed toward bg.sunken, with a heavier vignette at the edges.
  wallpaper = pkgs.runCommand "boot-menu-${themeName}.jpg"
    { nativeBuildInputs = [ pkgs.imagemagick ]; }
    ''
      magick ${menu.wallpaper} -resize '1920x1200^' -gravity center -extent 1920x1200 \
        -fill '${colors.bg.sunken}' -colorize 30% \
        \( -size 1920x1200 radial-gradient:white-black -evaluate pow 1.2 \) \
        -compose Multiply -composite -quality 90 "$out"
    '';
in
{
  wallpapers = lib.optional (menu ? wallpaper) wallpaper;
  wallpaperStyle = "stretched";
  backdrop = hex colors.bg.sunken;
  interface = {
    branding = menu.branding or null;
    brandingColor = hex colors.accent.primary;
    helpColor = hex colors.fg.muted;
    helpColorBright = hex colors.accent.primary;
  };
  graphicalTerminal = {
    palette = lib.concatStringsSep ";" (lib.sublist 0 8 console);
    brightPalette = lib.concatStringsSep ";" (lib.sublist 8 8 console);
    foreground = hex colors.fg.primary;
    brightForeground = hex colors.fg.primary;
    # TT is transparency: 0x78 leaves the panel just over half opaque.
    background = "78" + hex colors.bg.sunken;
    brightBackground = hex colors.bg.elevated;
    margin = 96;
    marginGradient = 48;
  };
}
