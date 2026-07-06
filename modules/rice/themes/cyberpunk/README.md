# Cyberpunk Theme

Phase 9 validation theme: deliberately **data-only**. Everything the
desktop shows comes from `_theme.nix` — tokens, fonts, glyph icon
overrides, glyph workspace identities, and the D-012 legacy palette.
No authored artwork, no plugins, no raster pipeline.

Contrast axis vs LOTM (what this theme is meant to stress):

- glyph workspace identities (LOTM: authored PNG emblems)
- glyph-only icon overrides (LOTM: SVG sigil files)
- hard radii + shorter motion durations (LOTM: soft + calm)
- display/sans font swap (Orbitron / Chakra Petch)

`assets/` holds role directories as they become needed. As of Phase 11
it ships `wallpapers/` (globbed into the manifest at build, D-019);
authored `preview.png` remains optional (derived swatch otherwise).
