# Rice themes' legacy-palette entries, merged into the classic
# palette registry (modules/themes/_palettes.nix). The theme manifest
# is upstream (D-012): each entry is `palette.legacy` from the theme's
# _theme.nix — never a duplicated color table.
{
  lotm = (import ../themes/lotm/_theme.nix).palette.legacy;
}
