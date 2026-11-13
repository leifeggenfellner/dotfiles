# Plymouth splash for a rice theme (D-044), built from the theme's
# `integration.boot` data and colour tokens at rebuild time:
#   sigil        single-colour SVG, recoloured to accent.primary
#   promptLabel  copy shown above the real passphrase/question prompt
#   font         optional TTF for prompt text (boot.plymouth.font)
# Fog, the ink-ring progress frames, and the bullet glyph are generated
# here, so a theme only supplies the sigil. Output follows the Plymouth
# theme layout: share/plymouth/themes/<name>/.
{ pkgs, lib }:
{ themeName, theme }:
let
  name = "rice-${themeName}";
  boot = theme.integration.boot;
  colors = theme.tokens.colors;

  channels = hex: map (offset: lib.fromHexString (builtins.substring offset 2 hex)) [ 1 3 5 ];
  # "#rrggbb" → "r, g, b" with 0–1 floats, the form Plymouth script takes.
  unit = c: let m = (c * 1000 + 127) / 255; in "${toString (m / 1000)}.${lib.fixedWidthString 3 "0" (toString (lib.mod m 1000))}";
  rgb = hex: lib.concatMapStringsSep ", " unit (channels hex);
  # Plymouth script string literal.
  scriptString = s: lib.replaceStrings [ "\\" "\"" "\n" ] [ "\\\\" "\\\"" " " ] s;

  ringFrames = 60;
  accent = colors.accent.primary;

  script = pkgs.replaceVars ./_plymouth-theme.script {
    bgTop = rgb colors.bg.sunken;
    bgBottom = rgb colors.bg.base;
    labelColor = rgb accent;
    textColor = rgb colors.fg.primary;
    mutedColor = rgb colors.fg.muted;
    promptLabel = scriptString (boot.promptLabel or "");
    font = scriptString (theme.tokens.typography.families.display or "Sans");
    ringFrames = toString ringFrames;
  };

  # Ink ring frame: a faint plain track, then the filled arc twice — a
  # blurred, wider pass that reads as ink soaking into paper and a crisp
  # pass on top — both roughened by a gentle turbulence displacement.
  ringSvg = ''
    ring() {
      local length="$1"
      cat <<EOF
    <svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" viewBox="0 0 400 400">
      <defs>
        <filter id="ink" x="-15%" y="-15%" width="130%" height="130%">
          <feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="2" seed="7" result="noise"/>
          <feDisplacementMap in="SourceGraphic" in2="noise" scale="5" xChannelSelector="R" yChannelSelector="G"/>
        </filter>
        <filter id="bleed" x="-15%" y="-15%" width="130%" height="130%">
          <feGaussianBlur stdDeviation="4" result="soft"/>
          <feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" seed="3" result="noise"/>
          <feDisplacementMap in="soft" in2="noise" scale="9" xChannelSelector="R" yChannelSelector="G"/>
        </filter>
      </defs>
      <g transform="rotate(-90 200 200)" fill="none" stroke="${accent}">
        <circle cx="200" cy="200" r="168" stroke-width="2" stroke-opacity="0.16"/>
        <circle cx="200" cy="200" r="168" stroke-width="12" stroke-opacity="0.35" stroke-linecap="round"
                stroke-dasharray="$length 2000" filter="url(#bleed)"/>
        <circle cx="200" cy="200" r="168" stroke-width="5" stroke-linecap="round"
                stroke-dasharray="$length 2000" filter="url(#ink)"/>
      </g>
    </svg>
    EOF
    }
  '';
in
pkgs.runCommand "plymouth-theme-${name}"
{
  nativeBuildInputs = [ pkgs.resvg pkgs.imagemagick ];
  passthru = { inherit name; };
} ''
  dir="$out/share/plymouth/themes/${name}"
  mkdir -p "$dir"

  # Sigil and glow on one padded canvas so the script scales them together.
  resvg --width 512 ${boot.sigil} sigil-raw.png
  magick sigil-raw.png -fill '${accent}' -colorize 100 \
    -background none -gravity center -extent 640x640 "$dir/sigil.png"
  # Blur only the alpha, then repaint: transparent pixels are black and
  # would otherwise bleed into a dark halo.
  magick "$dir/sigil.png" -channel A -blur 0x18 -evaluate multiply 0.9 +channel \
    -fill '${accent}' -colorize 100 "$dir/glow.png"

  # Fog: blurred fractal noise as the alpha of a fog-tinted layer, faded
  # out toward the top so the bank hugs the floor.
  magick -seed 7 -size 480x264 plasma:fractal -blur 0x14 -colorspace Gray -level 35%,95% noise.png
  magick -size 480x264 gradient:black-white -evaluate pow 0.6 floor.png
  magick noise.png floor.png -compose Multiply -composite alpha.png
  magick -size 480x264 'xc:${colors.accent.secondary}' alpha.png \
    -alpha off -compose CopyOpacity -composite "$dir/fog.png"

  magick -size 32x32 xc:none -fill '${accent}' -draw 'polygon 16,2 30,16 16,30 2,16' "$dir/bullet.png"

  ${ringSvg}
  for i in $(seq 0 ${toString (ringFrames - 1)}); do
    ring "$(awk -v i="$i" 'BEGIN { printf "%.2f", 2 * 3.14159265 * 168 * i / ${toString (ringFrames - 1)} }')" > ring.svg
    resvg ring.svg "$dir/ring-$i.png"
  done

  cp ${script} "$dir/${name}.script"
  cat > "$dir/${name}.plymouth" <<EOF
  [Plymouth Theme]
  Name=${name}
  Description=Rice boot splash for ${theme.meta.displayName or themeName}
  ModuleName=script

  [script]
  ImageDir=$dir
  ScriptFile=$dir/${name}.script
  EOF
''
