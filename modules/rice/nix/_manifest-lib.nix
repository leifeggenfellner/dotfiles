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
# lock-screen script prefers its first image entry over the live
# wallpaper, and Quickshell may use `assets.lockscreenVideos[0]` as an
# animated background when present.
{ pkgs, lib }:
{ themeName, themeDir, theme ? import (themeDir + "/_theme.nix") }:
let
  fail = msg: throw "rice theme '${themeName}': ${msg}";

  checkClosed = path: allowed: value:
    if !builtins.isAttrs value
    then fail "${path} must be an attrset"
    else
      let unknown = lib.subtractLists allowed (lib.attrNames value); in
      if unknown == [ ] then true
      else fail "${path} contains unknown keys: ${lib.concatStringsSep ", " unknown}";

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

  schemaChecks =
    [
      (checkClosed "manifest"
        [ "meta" "tokens" "palette" "assets" "widgets" "plugins" "integration" ]
        theme)
      (checkClosed "meta"
        [ "name" "displayName" "version" "schemaVersion" ]
        (theme.meta or { }))
      (checkClosed "tokens"
        [ "colors" "typography" "metrics" "motion" "effects" ]
        (theme.tokens or { }))
      (checkClosed "tokens.colors"
        (lib.attrNames colorSchema)
        (get [ "colors" ] tokens))
    ]
    ++ lib.mapAttrsToList
      (group: keys: checkClosed "tokens.colors.${group}" keys
        (get [ "colors" group ] tokens))
      colorSchema
    ++ [
      (checkClosed "tokens.typography"
        [ "families" "sizes" "weights" ]
        (get [ "typography" ] tokens))
      (checkClosed "tokens.typography.families"
        [ "display" "sans" "mono" ]
        (get [ "typography" "families" ] tokens))
      (checkClosed "tokens.typography.sizes"
        [ "small" "body" "bar" "heading" "icon" ]
        (get [ "typography" "sizes" ] tokens))
      (checkClosed "tokens.typography.weights"
        [ "regular" "medium" "bold" ]
        (get [ "typography" "weights" ] tokens))
      (checkClosed "tokens.metrics"
        [ "radius" "space" "bar" "workspaces" "dashboard" ]
        (get [ "metrics" ] tokens))
      (checkClosed "tokens.metrics.radius"
        [ "small" "medium" "large" ]
        (get [ "metrics" "radius" ] tokens))
      (checkClosed "tokens.metrics.space"
        [ "xs" "sm" "md" "lg" ]
        (get [ "metrics" "space" ] tokens))
      (checkClosed "tokens.metrics.bar"
        [ "height" "margin" "spacing" "opacity" ]
        (get [ "metrics" "bar" ] tokens))
      (checkClosed "tokens.metrics.workspaces"
        [ "slotSize" "ringExpansion" "iconSize" "iconSourceSize" ]
        (get [ "metrics" "workspaces" ] tokens))
      (checkClosed "tokens.metrics.dashboard"
        [ "columnCount" "compactBreakpoint" "sidebarRatio" "sidebarMinWidth" "sidebarMaxWidth" "mainMinWidth" "epigraphMinHeight" "defaultMinHeight" ]
        (get [ "metrics" "dashboard" ] tokens))
      (checkClosed "tokens.motion"
        [ "durations" "easings" "intensity" "ambient" "enabled" ]
        (get [ "motion" ] tokens))
      (checkClosed "tokens.motion.durations"
        [ "fast" "base" "slow" "overlay" "ceremonial" ]
        (get [ "motion" "durations" ] tokens))
      (checkClosed "tokens.motion.easings"
        [ "standard" "enter" "exit" "emphasis" ]
        (get [ "motion" "easings" ] tokens))
      (checkClosed "assets"
        [ "lockscreenVariant" "logo" "launcherIcon" "icons" "sounds" "art" "rasterize" ]
        (theme.assets or { }))
    ]
    ++ lib.optionals (tokens ? effects) [
      (checkClosed "tokens.effects" [ "layers" ] tokens.effects)
    ]
    ++ lib.mapAttrsToList
      (id: descriptor: checkClosed "widgets.${id}"
        [ "enabled" "region" "priority" "monitorPolicy" "settings" ]
        descriptor)
      (theme.widgets or { })
    ++ map
      (plugin: checkClosed "plugins entry"
        [ "id" "source" "entry" "region" "priority" "services" "layout" ]
        plugin)
      (theme.plugins or [ ])
    ++ lib.optionals (theme ? integration) (
      [
        (checkClosed "integration"
          [ "gtk" "qt" "cursor" "fonts" ]
          theme.integration)
      ]
      ++ lib.optionals (theme.integration ? gtk) [
        (checkClosed "integration.gtk" [ "theme" "iconTheme" ] theme.integration.gtk)
      ]
      ++ lib.optionals (theme.integration ? qt) [
        (checkClosed "integration.qt" [ "style" ] theme.integration.qt)
      ]
      ++ lib.optionals (theme.integration ? cursor) [
        (checkClosed "integration.cursor" [ "name" "size" ] theme.integration.cursor)
      ]
      ++ lib.optionals (theme.integration ? fonts) [
        (checkClosed "integration.fonts" [ "packages" ] theme.integration.fonts)
      ]
    );

  get = path: attrs:
    lib.attrByPath path (fail "missing tokens.${lib.concatStringsSep "." path}") attrs;

  metricDefaults = {
    workspaces = {
      slotSize = 30;
      ringExpansion = 4;
      iconSize = 24;
      iconSourceSize = 48;
    };
    dashboard = {
      columnCount = 12;
      compactBreakpoint = 1120;
      sidebarRatio = 0.46;
      sidebarMinWidth = 360;
      sidebarMaxWidth = 560;
      mainMinWidth = 440;
      epigraphMinHeight = 112;
      defaultMinHeight = 180;
    };
  };

  sourceTokens = theme.tokens;
  sourceMetrics = sourceTokens.metrics;
  tokens = sourceTokens // {
    metrics = sourceMetrics // {
      workspaces = sourceMetrics.workspaces or metricDefaults.workspaces;
      dashboard = sourceMetrics.dashboard or metricDefaults.dashboard;
    };
  };

  requireString = path:
    let value = get path tokens; in
    if builtins.isString value then value
    else fail "tokens.${lib.concatStringsSep "." path} must be a string";

  requireInt = path:
    let value = get path tokens; in
    if builtins.isInt value then value
    else fail "tokens.${lib.concatStringsSep "." path} must be an int";

  requireNumber = path:
    let value = get path tokens; in
    if builtins.isInt value || builtins.isFloat value then value
    else fail "tokens.${lib.concatStringsSep "." path} must be a number";

  tokenChecks =
    lib.flatten
      (lib.mapAttrsToList
        (group: keys: map (k: hex (get [ "colors" group k ] tokens)) keys)
        colorSchema)
    ++ map (f: requireString [ "typography" "families" f ]) [ "display" "sans" "mono" ]
    ++ map (s: requireInt [ "typography" "sizes" s ]) [ "small" "body" "bar" "heading" "icon" ]
    ++ map (w: requireInt [ "typography" "weights" w ]) [ "regular" "medium" "bold" ]
    ++ map (r: requireInt [ "metrics" "radius" r ]) [ "small" "medium" "large" ]
    ++ map (s: requireInt [ "metrics" "space" s ]) [ "xs" "sm" "md" "lg" ]
    ++ map (b: requireInt [ "metrics" "bar" b ]) [ "height" "margin" "spacing" ]
    ++ [ (requireNumber [ "metrics" "bar" "opacity" ]) ]
    ++ map (w: requireInt [ "metrics" "workspaces" w ]) [ "slotSize" "ringExpansion" "iconSize" "iconSourceSize" ]
    ++ map (d: requireInt [ "metrics" "dashboard" d ]) [ "columnCount" "compactBreakpoint" "sidebarMinWidth" "sidebarMaxWidth" "mainMinWidth" "epigraphMinHeight" "defaultMinHeight" ]
    ++ [ (requireNumber [ "metrics" "dashboard" "sidebarRatio" ]) ]
    ++ map (d: requireInt [ "motion" "durations" d ]) [ "fast" "base" "slow" "overlay" ]
    ++ map (e: requireString [ "motion" "easings" e ]) [ "standard" "enter" "exit" "emphasis" ];

  requirePositive = path:
    let value = get path tokens; in
    if value > 0 then true
    else fail "tokens.${lib.concatStringsSep "." path} must be positive";

  metricRangeChecks =
    map (name: requirePositive [ "metrics" "workspaces" name ])
      [ "slotSize" "ringExpansion" "iconSize" "iconSourceSize" ]
    ++ map (name: requirePositive [ "metrics" "dashboard" name ])
      [ "columnCount" "compactBreakpoint" "sidebarMinWidth" "sidebarMaxWidth" "mainMinWidth" "epigraphMinHeight" "defaultMinHeight" ]
    ++ [
      (if tokens.metrics.workspaces.iconSize <= tokens.metrics.workspaces.slotSize then true
      else fail "tokens.metrics.workspaces.iconSize must not exceed slotSize")
      (if tokens.metrics.workspaces.iconSourceSize >= tokens.metrics.workspaces.iconSize then true
      else fail "tokens.metrics.workspaces.iconSourceSize must be at least iconSize")
      (if tokens.metrics.dashboard.sidebarRatio > 0 && tokens.metrics.dashboard.sidebarRatio < 1 then true
      else fail "tokens.metrics.dashboard.sidebarRatio must be greater than 0 and less than 1")
      (if tokens.metrics.dashboard.sidebarMinWidth <= tokens.metrics.dashboard.sidebarMaxWidth then true
      else fail "tokens.metrics.dashboard.sidebarMinWidth must not exceed sidebarMaxWidth")
      (if tokens.metrics.dashboard.compactBreakpoint >= tokens.metrics.dashboard.sidebarMinWidth + tokens.metrics.space.md + tokens.metrics.dashboard.mainMinWidth then true
      else fail "tokens.metrics.dashboard.compactBreakpoint must fit sidebarMinWidth, mainMinWidth, and the dashboard gap")
    ];

  metaChecks = [
    (if (theme.meta.name or null) == themeName then true
    else fail "meta.name must equal '${themeName}'")
    (if builtins.isString (theme.meta.displayName or null) then true
    else fail "meta.displayName must be a string")
    (if builtins.isString (theme.meta.version or null) then true
    else fail "meta.version must be a string")
    (if builtins.isInt (theme.meta.schemaVersion or null)
      && theme.meta.schemaVersion == 2
    then true
    else fail "meta.schemaVersion must be the integer 2")
  ];

  # Motion v2 (D-022) + ambient effects (D-021): ceremonial is optional;
  # the global controls below are required and typechecked. Easing names
  # resolve (warn-and-default) in the runtime; only their shape is enforced.
  motionExtraChecks =
    [
      (
        let c = tokens.motion.durations.ceremonial or null; in
        if c == null || builtins.isInt c then true
        else fail "tokens.motion.durations.ceremonial must be an int (ms)"
      )
      (if lib.elem (get [ "motion" "intensity" ] tokens) [ "calm" "lively" ] then true
      else fail "tokens.motion.intensity must be one of [calm lively]")
      (if builtins.isBool (get [ "motion" "ambient" ] tokens) then true
      else fail "tokens.motion.ambient must be a bool")
      (if builtins.isBool (get [ "motion" "enabled" ] tokens) then true
      else fail "tokens.motion.enabled must be a bool")
    ];

  effectTypes = [ "fog" "particles" "vignette" ];
  # Tints are color TOKEN REFS (L-005: effects derive from tokens,
  # never literal colors): "<bg|fg|accent|state>.<key>". The reference
  # path is relative to tokens.colors and must resolve there.
  isTokenRef = v:
    builtins.isString v
    && builtins.match "(bg|fg|accent|state)\\.[a-zA-Z0-9]+" v != null
    && lib.hasAttrByPath (lib.splitString "." v) tokens.colors;
  effectChecks =
    let
      layers =
        if tokens ? effects
        then tokens.effects.layers or (fail "missing tokens.effects.layers")
        else [ ];
    in
    if !builtins.isList layers
    then fail "tokens.effects.layers must be a list"
    else
      map
        (l:
          if !builtins.isAttrs l
          then fail "tokens.effects layers must be attrsets"
          else if !(checkClosed "tokens.effects layer"
            [ "type" "tint" "opacity" "speed" "count" "band" ]
            l)
          then false
          else if !(lib.elem (l.type or null) effectTypes)
          then fail "tokens.effects layer type must be one of [${lib.concatStringsSep " " effectTypes}], got ${builtins.toJSON (l.type or null)}"
          else if !(l ? tint) || !isTokenRef l.tint
          then fail "tokens.effects tint is required and must resolve to an existing color token ref like \"accent.primary\" (L-005), got ${builtins.toJSON (l.tint or null)}"
          else true)
        layers;

  iconChecks = lib.mapAttrsToList
    (name: value:
      if lib.hasInfix "/" value && !builtins.pathExists (themeDir + "/assets/${value}")
      then fail "icon '${name}' points to missing file assets/${value}"
      else true)
    (theme.assets.icons or { });

  soundChecks = lib.mapAttrsToList
    (name: value:
      if !builtins.isString value
      then fail "sound '${name}' must be a file path string"
      else if !builtins.pathExists (themeDir + "/assets/${value}")
      then fail "sound '${name}' points to missing file assets/${value}"
      else true)
    (theme.assets.sounds or { });

  pluginSourcePath = plugin:
    let source = plugin.source or (fail "plugin '${plugin.id or "<missing-id>"}' is missing source"); in
    if builtins.isString source then themeDir + "/${source}"
    else fail "plugin '${plugin.id or "<missing-id>"}' source must be a theme-relative string";

  pluginEntry = plugin:
    "${plugin.source}/${plugin.entry or "main.qml"}";

  plugins = map
    (plugin:
      plugin // {
        contractVersion = plugin.contractVersion or 1;
        enabled = plugin.enabled or true;
        region = plugin.region or "dashboard";
        priority = plugin.priority or 50;
        services = plugin.services or [ ];
        entry = pluginEntry plugin;
        source = "${themeDir}";
      })
    (theme.plugins or [ ]);

  pluginChecks = map
    (plugin:
      let sourcePath = pluginSourcePath plugin; in
      if !(builtins.isString (plugin.id or null)) || plugin.id == ""
      then fail "plugins entries must have a non-empty string id"
      else if !(builtins.pathExists sourcePath)
      then fail "plugin '${plugin.id}' source does not exist: ${toString sourcePath}"
      else if !(builtins.pathExists (sourcePath + "/${plugin.entry or "main.qml"}"))
      then fail "plugin '${plugin.id}' entry does not exist: ${toString sourcePath}/${plugin.entry or "main.qml"}"
      else if !(builtins.isList (plugin.services or [ ]))
      then fail "plugin '${plugin.id}' services must be a list"
      else true)
    (theme.plugins or [ ]);

  rasterize = theme.assets.rasterize or [ ];

  # Build-time image enumeration (D-019/D-020): image-role dirs are
  # globbed, never hand-listed. Missing/empty dir → []. Entries are
  # "${assetsRoot}/<subdir>/<file>" so they share the assets-dir
  # store copy (and its GC context) with assets.root.
  imageExts = [ ".png" ".jpg" ".jpeg" ".webp" ];
  videoExts = [ ".mp4" ".webm" ".mkv" ];
  assetsRoot = "${themeDir + "/assets"}";
  globMedia = exts: subdir:
    let src = themeDir + "/assets/${subdir}"; in
    if builtins.pathExists src then
      map (f: "${assetsRoot}/${subdir}/${f}")
        (lib.naturalSort (lib.filter
          (n: lib.any (e: lib.hasSuffix e (lib.toLower n)) exts)
          (lib.attrNames (lib.filterAttrs (_: t: t == "regular")
            (builtins.readDir src)))))
    else [ ];
  globImages = globMedia imageExts;
  wallpapers = globImages "wallpapers";
  lockscreen = globImages "lockscreen"; # lock-screen uses entry [0]
  lockscreenVideos = globMedia videoExts "lockscreen";

  rasterChecks = map
    (r:
      if builtins.pathExists (themeDir + "/assets/${r.src}")
      then true
      else fail "rasterize source assets/${r.src} does not exist")
    rasterize;

  # Optional theme-declared lock variant. Selects which
  # ~/.config/quickshell/rice/lock-*.qml root the rice-lock-screen
  # launcher starts. CLI --variant and RICE_LOCK_VARIANT still win.
  lockscreenVariants = [ "default" "lotm" ];
  lockscreenVariant =
    let v = theme.assets.lockscreenVariant or null; in
    if v == null then null
    else if !(builtins.isString v)
    then fail "assets.lockscreenVariant must be a string"
    else if !(lib.elem v lockscreenVariants)
    then fail "assets.lockscreenVariant must be one of [${lib.concatStringsSep " " lockscreenVariants}], got ${builtins.toJSON v}"
    else v;

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
    inherit tokens;
    inherit plugins;
    assets = (removeAttrs (theme.assets or { }) [ "rasterize" "lockscreenVariant" ]) // {
      inherit raster wallpapers lockscreen lockscreenVideos;
      # Interpolation (not toString) so the store-path CONTEXT lands in
      # the JSON — otherwise the source snapshot is not a GC reference
      # of the manifest and can be collected while the manifest lives.
      root = assetsRoot;
    } // (lib.optionalAttrs (lockscreenVariant != null) {
      inherit lockscreenVariant;
    });
  };

  checks = schemaChecks ++ tokenChecks ++ metricRangeChecks ++ metaChecks ++ iconChecks ++ soundChecks ++ rasterChecks
    ++ motionExtraChecks ++ effectChecks ++ pluginChecks;
in
{
  inherit manifest;
  validated = builtins.deepSeq checks true;
  json = builtins.deepSeq checks
    (pkgs.writeText "rice-manifest-${themeName}.json" (builtins.toJSON manifest));
}
