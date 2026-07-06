# mkThemeManifest — validates a theme's manifest source and produces
# the runtime JSON (contracts/theme-manifest.md). A broken theme fails
# at eval/build, never in the running shell.
#
# Also runs the raster pipeline (D-011): theme-declared
# `assets.rasterize = [ { name; src; size; } ]` renders every SVG in
# assets/<src>/ to PNG at build time; outputs land in the manifest as
# `assets.raster.<name>` (store path). SVG stays the single source.
{ pkgs, lib }:
{ themeName, themeDir }:
let
  theme = import (themeDir + "/_theme.nix");

  fail = msg: throw "rice theme '${themeName}': ${msg}";

  hex = v:
    if builtins.isString v && builtins.match "#[0-9a-fA-F]{6}" v != null
    then v
    else fail "expected #rrggbb color, got ${builtins.toJSON v}";

  # Closed-core token schema (D-005): these keys must exist and typecheck.
  colorSchema = {
    bg = [ "base" "mantle" "elevated" "sunken" "surface1" "surface2" ];
    fg = [ "primary" "muted" "subtle" ];
    accent = [ "primary" "secondary" "tertiary" ];
    state = [ "ok" "warn" "danger" "info" ];
  };

  get = path: attrs:
    lib.attrByPath path (fail "missing tokens.${lib.concatStringsSep "." path}") attrs;

  tokenChecks =
    lib.flatten
      (lib.mapAttrsToList
        (group: keys: map (k: hex (get [ "colors" group k ] theme.tokens)) keys)
        colorSchema)
    ++ map (f: get [ "typography" "families" f ] theme.tokens) [ "display" "sans" "mono" ]
    ++ map (d: get [ "motion" "durations" d ] theme.tokens) [ "fast" "base" "slow" "overlay" ];

  metaChecks = [
    (if (theme.meta.name or null) == themeName then true
    else fail "meta.name must equal '${themeName}'")
    (theme.meta.schemaVersion or (fail "missing meta.schemaVersion"))
  ];

  iconChecks = lib.mapAttrsToList
    (name: value:
      if lib.hasInfix "/" value && !builtins.pathExists (themeDir + "/assets/${value}")
      then fail "icon '${name}' points to missing file assets/${value}"
      else true)
    (theme.assets.icons or { });

  rasterize = theme.assets.rasterize or [ ];

  rasterChecks = map
    (r:
      if builtins.pathExists (themeDir + "/assets/${r.src}")
      then true
      else fail "rasterize source assets/${r.src} does not exist")
    rasterize;

  raster = lib.listToAttrs (map
    (r: {
      inherit (r) name;
      value = "${pkgs.runCommand "rice-${themeName}-raster-${r.name}"
        { nativeBuildInputs = [ pkgs.resvg ]; } ''
        mkdir -p $out
        for f in ${themeDir + "/assets/${r.src}"}/*.svg; do
          resvg --width ${toString r.size} "$f" "$out/$(basename "$f" .svg).png"
        done
      ''}";
    })
    rasterize);

  manifest = theme // {
    assets = (removeAttrs (theme.assets or { }) [ "rasterize" ]) // {
      inherit raster;
      # Interpolation (not toString) so the store-path CONTEXT lands in
      # the JSON — otherwise the source snapshot is not a GC reference
      # of the manifest and can be collected while the manifest lives.
      root = "${themeDir + "/assets"}";
    };
  };

  checks = tokenChecks ++ metaChecks ++ iconChecks ++ rasterChecks;
in
{
  inherit manifest;
  json = builtins.deepSeq checks
    (pkgs.writeText "rice-manifest-${themeName}.json" (builtins.toJSON manifest));
}
