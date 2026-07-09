# mkThemeIndex — builds EVERY theme under modules/rice/themes/ and
# writes the themes.json index the switch machinery reads (D-003,
# D-018). Each entry carries the validated manifest store path, a
# preview image, and the theme's wallpaper list so rice-switch can
# orchestrate wallpapers without evaluating Nix at switch time.
#
# Preview resolution (D-018): an authored assets/preview.png wins
# (authored art is source, D-017); otherwise a swatch card is
# derived from the theme's own tokens at build time (D-011 — never
# hand-maintained).
{ pkgs, lib }:
{ defaultTheme, themePackages ? null }:
let
  themeLib = import ./_themes-lib.nix { inherit lib; };
  mkThemeManifest = import ./_manifest-lib.nix { inherit pkgs lib; };
  packages = if themePackages == null then themeLib.bundledThemePackages else themePackages;
  themeNames = lib.attrNames packages;

  swatchPreview = name: tokens:
    let c = tokens.colors; in
    pkgs.runCommand "rice-preview-${name}.png"
      { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      magick -size 320x180 xc:'${c.bg.base}' \
        -fill '${c.bg.elevated}' -draw 'roundrectangle 16,16 304,110 6,6' \
        -fill '${c.bg.surface1}' -draw 'roundrectangle 16,124 304,140 3,3' \
        -fill '${c.accent.primary}'   -draw 'roundrectangle 16,150 110,164 3,3' \
        -fill '${c.accent.secondary}' -draw 'roundrectangle 118,150 212,164 3,3' \
        -fill '${c.accent.tertiary}'  -draw 'roundrectangle 220,150 304,164 3,3' \
        -fill '${c.fg.primary}' -draw 'roundrectangle 32,32 180,44 3,3' \
        -fill '${c.fg.muted}'   -draw 'roundrectangle 32,56 240,64 2,2' \
        -fill '${c.fg.subtle}'  -draw 'roundrectangle 32,76 210,84 2,2' \
        $out
    '';

  entry = name:
    let
      themeDir = packages.${name};
      built = mkThemeManifest { themeName = name; inherit themeDir; };
      authored = themeDir + "/assets/preview.png";
    in
    {
      displayName = built.manifest.meta.displayName or name;
      manifest = "${built.json}";
      preview =
        if builtins.pathExists authored
        then "${authored}"
        else "${swatchPreview name built.manifest.tokens}";
      wallpapers = built.manifest.assets.wallpapers or [ ];
    };

  index = {
    schemaVersion = 1;
    default = defaultTheme;
    themes = lib.genAttrs themeNames entry;
  };
in
assert lib.assertMsg (lib.elem defaultTheme themeNames)
  "rice: default theme '${defaultTheme}' has no configured theme package";
{
  inherit index;
  json = pkgs.writeText "rice-themes-index.json" (builtins.toJSON index);
}
