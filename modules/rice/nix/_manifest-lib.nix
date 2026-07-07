# mkThemeManifest — validates a theme's manifest source and produces
# the runtime JSON (contracts/theme-manifest.md). A broken theme fails
# at eval/build, never in the running shell.
#
# Also runs the raster pipeline (D-011): theme-declared
# `assets.rasterize = [ { name; src; size; } ]` renders every SVG in
# assets/<src>/ to PNG at build time; outputs land in the manifest as
# `assets.raster.<name>` (store path). SVG stays the single source.
#
# Wallpapers (D-019): assets/wallpapers/ is enumerated at eval into
# `assets.wallpapers` (sorted store paths); themes never hand-list.
# Same for assets/lockscreen/ → `assets.lockscreen` (D-020): the
# lock-screen script prefers its first entry over the live wallpaper.
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

  # Motion v2 (D-022) + ambient effects (D-021): optional keys,
  # typechecked when present so a theme typo fails the build, never
  # the running shell. Easing names resolve (warn-and-default) in
  # the runtime; only the shape is enforced here.
  motionExtraChecks =
    lib.mapAttrsToList
      (k: v:
        if builtins.isString v then true
        else fail "tokens.motion.easings.${k} must be a curve-name string")
      (theme.tokens.motion.easings or { })
    ++ [
      (
        let c = theme.tokens.motion.durations.ceremonial or null; in
        if c == null || builtins.isInt c then true
        else fail "tokens.motion.durations.ceremonial must be an int (ms)"
      )
    ];

  effectTypes = [ "fog" "particles" "vignette" ];
  # Tints are color TOKEN REFS (L-005: effects derive from tokens,
  # never literal colors): "<bg|fg|accent|state>.<key>".
  isTokenRef = v:
    builtins.isString v
    && builtins.match "(bg|fg|accent|state)\\.[a-zA-Z0-9]+" v != null;
  effectChecks =
    let layers = (theme.tokens.effects or { }).layers or [ ]; in
    if !builtins.isList layers
    then fail "tokens.effects.layers must be a list"
    else
      map
        (l:
          if !(lib.elem (l.type or null) effectTypes)
          then fail "tokens.effects layer type must be one of [${lib.concatStringsSep " " effectTypes}], got ${builtins.toJSON (l.type or null)}"
          else if l ? tint && !isTokenRef l.tint
          then fail "tokens.effects tint must be a color token ref like \"accent.primary\" (L-005), got ${builtins.toJSON l.tint}"
          else true)
        layers;

  iconChecks = lib.mapAttrsToList
    (name: value:
      if lib.hasInfix "/" value && !builtins.pathExists (themeDir + "/assets/${value}")
      then fail "icon '${name}' points to missing file assets/${value}"
      else true)
    (theme.assets.icons or { });

  rasterize = theme.assets.rasterize or [ ];

  # Build-time image enumeration (D-019/D-020): image-role dirs are
  # globbed, never hand-listed. Missing/empty dir → []. Entries are
  # "${assetsRoot}/<subdir>/<file>" so they share the assets-dir
  # store copy (and its GC context) with assets.root.
  imageExts = [ ".png" ".jpg" ".jpeg" ".webp" ];
  assetsRoot = "${themeDir + "/assets"}";
  globImages = subdir:
    let src = themeDir + "/assets/${subdir}"; in
    if builtins.pathExists src then
      map (f: "${assetsRoot}/${subdir}/${f}")
        (lib.naturalSort (lib.filter
          (n: lib.any (e: lib.hasSuffix e (lib.toLower n)) imageExts)
          (lib.attrNames (lib.filterAttrs (_: t: t == "regular")
            (builtins.readDir src)))))
    else [ ];
  wallpapers = globImages "wallpapers";
  lockscreen = globImages "lockscreen"; # lock-screen uses entry [0]

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
      inherit raster wallpapers lockscreen;
      # Interpolation (not toString) so the store-path CONTEXT lands in
      # the JSON — otherwise the source snapshot is not a GC reference
      # of the manifest and can be collected while the manifest lives.
      root = assetsRoot;
    };
  };

  checks = tokenChecks ++ metaChecks ++ iconChecks ++ rasterChecks
    ++ motionExtraChecks ++ effectChecks;
in
{
  inherit manifest;
  json = builtins.deepSeq checks
    (pkgs.writeText "rice-manifest-${themeName}.json" (builtins.toJSON manifest));
}
