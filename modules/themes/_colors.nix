let
  c = import ./_palette.nix;
in
_: {
  colorScheme = {
    slug = "catppuccin-mocha";
    name = "Catppuccin Mocha";
    author = "Catppuccin Community";
    palette = {
      base00 = c.base;
      base01 = c.mantle;
      base02 = c.surface0;
      base03 = c.surface1;
      base04 = c.surface2;
      base05 = c.text;
      base06 = c.rosewater;
      base07 = c.lavender;
      base08 = c.red;
      base09 = c.peach;
      base0A = c.yellow;
      base0B = c.green;
      base0C = c.teal;
      base0D = c.blue;
      base0E = c.mauve;
      base0F = c.maroon;
    };
  };
}

