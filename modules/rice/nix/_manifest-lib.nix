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

  checkUnloadWhenClosed = path: descriptor:
    if !(descriptor ? unloadWhenClosed) || builtins.isBool descriptor.unloadWhenClosed
    then true
    else fail "${path}.unloadWhenClosed must be a bool";

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
        [ "colors" "typography" "metrics" "motion" "effects" "chrome" ]
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
        [ "durations" "easings" "intensity" "ambient" "enabled" "compositor" ]
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
      (checkClosed "tokens.effects" [ "layers" "presets" ] tokens.effects)
    ]
    ++ lib.mapAttrsToList
      (id: descriptor: checkClosed "widgets.${id}"
        [ "enabled" "region" "priority" "monitorPolicy" "settings" "unloadWhenClosed" ]
        descriptor)
      (theme.widgets or { })
    ++ lib.optionals ((theme.widgets.dailyAccent.settings or null) != null) (
      # Daily accent (D-054): an extras record resolved against a theme
      # list; every entry's accent and sigil must resolve.
      let
        at = "widgets.dailyAccent.settings";
        s = theme.widgets.dailyAccent.settings;
        record = lib.splitString "." (s.record or "");
        catalog =
          if builtins.isString (s.catalog or null)
          then lib.attrByPath (lib.splitString "." s.catalog) null theme
          else null;
        entryCheck = i: e:
          let entryAt = "${s.catalog}.${toString i}"; in
          if !(e ? accent) then true
          else if !(builtins.isString (e.id or null)) || builtins.match "[A-Za-z0-9_-]+" e.id == null
          then fail "${entryAt}.id must match [A-Za-z0-9_-]+ when it carries an accent"
          else if !(builtins.seq (hex e.accent) true) then false
          else if e ? sigil && !(builtins.isString e.sigil && lib.hasSuffix ".svg" e.sigil
          && builtins.pathExists (themeDir + "/assets/${e.sigil}"))
          then fail "${entryAt}.sigil must be an .svg under assets/, got ${builtins.toJSON e.sigil}"
          else true;
      in
      [
        (checkClosed at [ "record" "catalog" ] s)
        (if builtins.length record == 3 && builtins.head record == "extras" then true
        else fail "${at}.record must be extras.<namespace>.<key>")
        (if builtins.isList catalog then true
        else fail "${at}.catalog must name a list in the theme")
      ]
      ++ lib.optionals (builtins.isList catalog) (lib.imap0 entryCheck catalog)
    )
    ++ lib.optionals ((theme.widgets.correspondence.settings.personas or null) != null) (
      # Notification personas (D-056): dressing for chosen apps' toasts.
      # Variants are the runtime's closed set; a sound must be one of
      # the theme's, an icon is any name Theme.icon resolves.
      let
        personas = theme.widgets.correspondence.settings.personas;
        personaCheck = i: p:
          let
            at = "widgets.correspondence.settings.personas.${toString i}";
            sound = p.sound or null;
          in
          builtins.seq (checkClosed at [ "apps" "label" "icon" "sound" "variant" ] p) (
            if !(builtins.isList (p.apps or null) && p.apps != [ ] && lib.all builtins.isString p.apps)
            then fail "${at}.apps must be a non-empty list of app names"
            else if !(builtins.isString (p.label or null)) then fail "${at}.label must be a string"
            else if (p.variant or "letter") != "letter" then fail "${at}.variant must be \"letter\""
            else if p ? sound && !(builtins.isString sound && (theme.assets.sounds or { }) ? ${sound})
            then fail "${at}.sound must name an entry in assets.sounds"
            else if p ? icon && !builtins.isString p.icon then fail "${at}.icon must be an icon name"
            else true
          );
      in
      if builtins.isList personas then lib.imap0 personaCheck personas
      else [ (fail "widgets.correspondence.settings.personas must be a list") ]
    )
    ++ lib.optionals ((theme.widgets.correspondence.settings.ceremony or null) != null) (
      # Toast ceremony (D-082): every toast a letter on paper, sealed in
      # wax and burnt away. Colours are token refs, `seal` an .svg under
      # assets/, `hand` and `print` font family names.
      let
        at = "widgets.correspondence.settings.ceremony";
        s = theme.widgets.correspondence.settings.ceremony;
        colourKeys = [ "paper" "ink" "wax" "ember" ];
      in
      if !(builtins.isAttrs s) then [ (fail "${at} must be an attrset") ]
      else
        [ (checkClosed at (colourKeys ++ [ "seal" "hand" "print" ]) s) ]
        ++ map
          (k: if !(s ? ${k}) || isTokenRef s.${k} then true else fail "${at}.${k} must be a colour token ref")
          colourKeys
        ++ [
          (if !(s ? seal) || (builtins.isString s.seal && lib.hasSuffix ".svg" s.seal
          && builtins.pathExists (themeDir + "/assets/${s.seal}")) then true
          else fail "${at}.seal must name an .svg under assets/")
        ]
        ++ map
          (k: if !(s ? ${k}) || (builtins.isString s.${k} && s.${k} != "") then true else fail "${at}.${k} must be a font family name")
          [ "hand" "print" ]
    )
    ++ lib.optionals ((theme.widgets.soundscape.settings or null) != null) (
      # Sound bed (D-058): looped layers keyed on sky conditions or a
      # workspace mood; every sound must be one of the theme's.
      let
        s = theme.widgets.soundscape.settings;
        moods = theme.widgets.mood.settings.workspaces or { };
        layerCheck = i: l:
          let at = "widgets.soundscape.settings.layers.${toString i}"; in
          builtins.seq (checkClosed at [ "sound" "volume" "when" "mood" ] l) (
            if !(builtins.isString (l.sound or null) && (theme.assets.sounds or { }) ? ${l.sound})
            then fail "${at}.sound must name an entry in assets.sounds"
            else if l ? volume && !(builtins.isFloat l.volume || builtins.isInt l.volume) || (l.volume or 1) < 0 || (l.volume or 1) > 1
            then fail "${at}.volume must be a number from 0 to 1"
            else if l ? when && !(builtins.elem l.when [ "rain" "fog" "fullMoon" ])
            then fail "${at}.when must be one of rain, fog, fullMoon"
            else if l ? mood && !(builtins.isString l.mood && moods ? ${l.mood})
            then fail "${at}.mood must name a workspace in widgets.mood.settings.workspaces"
            else true
          );
      in
      [ (checkClosed "widgets.soundscape.settings" [ "layers" ] s) ]
      ++ (if builtins.isList (s.layers or null) then lib.imap0 layerCheck s.layers
      else [ (fail "widgets.soundscape.settings.layers must be a list") ])
    )
    ++ lib.optionals ((theme.widgets.newtab.settings or null) != null) (
      # Browser new-tab page (D-060): copy, epigraphs as a list or a theme
      # path, and a daily record resolved like the terminal greeting's.
      let
        at = "widgets.newtab.settings";
        s = theme.widgets.newtab.settings;
        str = key: v: if builtins.isString v then true else fail "${at}.${key} must be a string";
        listPath = p: builtins.isString p && builtins.isList (lib.attrByPath (lib.splitString "." p) null theme);
      in
      [
        (checkClosed at [ "title" "tagline" "epigraphs" "daily" "labels" ] s)
        (str "title" (s.title or ""))
        (str "tagline" (s.tagline or ""))
        (if !(s ? epigraphs) || builtins.isList s.epigraphs || listPath s.epigraphs then true
        else fail "${at}.epigraphs must be a list or name a list in the theme")
        (checkClosed "${at}.labels" [ "weather" "moon" "omen" "links" "offline" "unavailable" ] (s.labels or { }))
      ]
      ++ lib.mapAttrsToList (k: str "labels.${k}") (s.labels or { })
      ++ lib.optionals (s ? daily) [
        (checkClosed "${at}.daily" [ "record" "catalog" "format" "pendingLabel" ] s.daily)
        (if builtins.match "extras[.][^.]+[.][^.]+" (s.daily.record or "") != null then true
        else fail "${at}.daily.record must be extras.<namespace>.<key>")
        (if listPath (s.daily.catalog or null) then true
        else fail "${at}.daily.catalog must name a list in the theme")
      ]
    )
    ++ lib.optionals ((theme.widgets.polkit.settings or null) != null) (
      # Polkit prompt copy (D-062): strings only; `sound` names a theme sound.
      let
        at = "widgets.polkit.settings";
        s = theme.widgets.polkit.settings;
      in
      [ (checkClosed at [ "title" "epigraph" "submitLabel" "cancelLabel" "identityLabel" "maskCharacter" "retryText" "icon" "sound" ] s) ]
      ++ lib.mapAttrsToList (k: v: if builtins.isString v then true else fail "${at}.${k} must be a string") s
      ++ lib.optional (s ? sound && !((theme.assets.sounds or { }) ? ${s.sound}))
        (fail "${at}.sound must name a sound in assets.sounds")
    )
    ++ lib.optionals ((theme.widgets.system.settings or null) != null) (
      # Instruments (D-064): the system glance's thresholds and gauge.
      let
        at = "widgets.system.settings";
        s = theme.widgets.system.settings;
        fraction = key: v:
          if (builtins.isFloat v || builtins.isInt v) && v >= 0 && v <= 1 then true
          else fail "${at}.${key} must be a number from 0 to 1";
        bool = key: v: if builtins.isBool v then true else fail "${at}.${key} must be a bool";
      in
      [ (checkClosed at [ "bluetooth" "showTray" "batteryGauge" "lowBattery" "criticalBattery" ] s) ]
      ++ lib.optional (s ? bluetooth) (bool "bluetooth" s.bluetooth)
      ++ lib.optional (s ? showTray) (bool "showTray" s.showTray)
      ++ lib.optional (s ? lowBattery) (fraction "lowBattery" s.lowBattery)
      ++ lib.optional (s ? criticalBattery) (fraction "criticalBattery" s.criticalBattery)
      ++ lib.optionals (s ? batteryGauge) [
        (checkClosed "${at}.batteryGauge" [ "full" "empty" ] s.batteryGauge)
        (fraction "batteryGauge.full" (s.batteryGauge.full or 0))
        (fraction "batteryGauge.empty" (s.batteryGauge.empty or 1))
        (if (s.batteryGauge.full or 0) < (s.batteryGauge.empty or 1) then true
        else fail "${at}.batteryGauge.full must sit above empty")
      ]
    )
    ++ lib.optionals ((theme.widgets.media.settings or null) != null) (
      let
        at = "widgets.media.settings";
        s = theme.widgets.media.settings;
      in
      [ (checkClosed at [ "idleTitle" "title" "maxTitleWidth" "hideIdle" "disc" ] s) ]
      ++ lib.optional (s ? idleTitle && !builtins.isString s.idleTitle) (fail "${at}.idleTitle must be a string")
      ++ lib.optional (s ? title && !builtins.isString s.title) (fail "${at}.title must be a string")
      ++ lib.optional (s ? maxTitleWidth && !(builtins.isInt s.maxTitleWidth && s.maxTitleWidth > 0))
        (fail "${at}.maxTitleWidth must be a positive int")
      ++ lib.optional (s ? hideIdle && !builtins.isBool s.hideIdle) (fail "${at}.hideIdle must be a bool")
      ++ lib.optional (s ? disc && !builtins.isBool s.disc) (fail "${at}.disc must be a bool")
    )
    ++ lib.optionals ((theme.widgets."monitor-profile".settings or null) != null) (
      let
        at = "widgets.monitor-profile.settings";
        s = theme.widgets."monitor-profile".settings;
      in
      [ (checkClosed at [ "maxLabelWidth" "showLabel" ] s) ]
      ++ lib.optional (s ? showLabel && !builtins.isBool s.showLabel) (fail "${at}.showLabel must be a bool")
      ++ lib.optional (s ? maxLabelWidth && !(builtins.isInt s.maxLabelWidth && s.maxLabelWidth > 0))
        (fail "${at}.maxLabelWidth must be a positive int")
    )
    ++ lib.optionals ((theme.widgets.tray.settings or null) != null) (
      # Tray hatch (D-064): how many icons ride the bar, and their tone.
      let
        at = "widgets.tray.settings";
        s = theme.widgets.tray.settings;
      in
      [ (checkClosed at [ "maxInline" "tone" "title" ] s) ]
      ++ lib.optional (s ? maxInline && !(builtins.isInt s.maxInline && s.maxInline >= 1 && s.maxInline <= 6))
        (fail "${at}.maxInline must be an int from 1 to 6")
      ++ lib.optional (s ? tone && !(builtins.elem s.tone [ "none" "sepia" ])) (fail "${at}.tone must be none or sepia")
      ++ lib.optional (s ? title && !builtins.isString s.title) (fail "${at}.title must be a string")
    )
    ++ lib.optionals ((theme.widgets.workspaces.settings.bezel or null) != null) (
      # Sigil bezels (D-065): plates and needle are files under assets/;
      # the urgent rim is a colour token ref (L-005).
      let
        at = "widgets.workspaces.settings.bezel";
        s = theme.widgets.workspaces.settings.bezel;
        asset = key:
          if builtins.isString s.${key} && builtins.pathExists (themeDir + "/assets/${s.${key}}") then true
          else fail "${at}.${key} must name a file under assets/, got ${builtins.toJSON s.${key}}";
      in
      [ (checkClosed at [ "plate" "activePlate" "needle" "urgent" ] s) ]
      ++ map asset (lib.intersectLists [ "plate" "activePlate" "needle" ] (lib.attrNames s))
      ++ lib.optional
        (s ? urgent && !(builtins.isString s.urgent
        && builtins.match "(bg|fg|accent|state)[.][a-z0-9]+" s.urgent != null))
        (fail "${at}.urgent must be a colour token ref")
    )
    ++ lib.optionals ((theme.widgets.workspaces.settings.carousel or null) != null) (
      # Workspace carousel (D-067): nine-sliced card and nameplate pieces
      # under assets/, the window-count copy ({n} is the count) and, from
      # D-068, window captures.
      let
        at = "widgets.workspaces.settings.carousel";
        s = theme.widgets.workspaces.settings.carousel;
        piece = key: p:
          if !(builtins.isAttrs p) then fail "${at}.${key} must be { src; slice; }"
          else
            builtins.seq (checkClosed "${at}.${key}" [ "src" "slice" ] p) (
              if !(builtins.isString (p.src or null) && builtins.pathExists (themeDir + "/assets/${p.src}"))
              then fail "${at}.${key}.src must name a file under assets/, got ${builtins.toJSON (p.src or null)}"
              else if !(builtins.isList (p.slice or null) && builtins.length p.slice == 4
              && lib.all (n: builtins.isInt n && n >= 0) p.slice)
              then fail "${at}.${key}.slice must be four non-negative ints [left top right bottom]"
              else true
            );
      in
      [ (checkClosed at [ "card" "nameplate" "copy" "capture" ] s) ]
      ++ lib.optional (s ? card) (piece "card" s.card)
      ++ lib.optional (s ? nameplate) (piece "nameplate" s.nameplate)
      ++ lib.optionals (s ? copy) (
        [ (checkClosed "${at}.copy" [ "none" "one" "many" ] s.copy) ]
        ++ lib.mapAttrsToList (k: v: if builtins.isString v then true else fail "${at}.copy.${k} must be a string") s.copy
      )
      # Window captures (D-068): present turns them on; the tint is a
      # colour token ref and strength how far it colours them.
      ++ lib.optionals (s ? capture) [
        (if builtins.isAttrs s.capture then checkClosed "${at}.capture" [ "tint" "strength" ] s.capture
        else fail "${at}.capture must be { tint?; strength?; }")
        (if !(s.capture ? tint) || (builtins.isString s.capture.tint
        && builtins.match "(bg|fg|accent|state)[.][a-z0-9]+" s.capture.tint != null) then true
        else fail "${at}.capture.tint must be a colour token ref")
        (if !(s.capture ? strength) || ((builtins.isFloat s.capture.strength || builtins.isInt s.capture.strength)
        && s.capture.strength >= 0 && s.capture.strength <= 1) then true
        else fail "${at}.capture.strength must be a number from 0 to 1")
      ]
    )
    ++ lib.optionals ((theme.widgets.awakening.settings or null) != null) (
      # Session awakening (D-053): closed keys.
      let
        at = "widgets.awakening.settings";
        s = theme.widgets.awakening.settings;
        ms = key: lo: hi:
          if !(s ? ${key}) || (builtins.isInt s.${key} && s.${key} >= lo && s.${key} <= hi) then true
          else fail "${at}.${key} must be an int from ${toString lo} to ${toString hi}";
      in
      [
        (checkClosed at [ "title" "subtitle" "hold" "lift" "sound" ] s)
        (if builtins.isString (s.title or null) then true else fail "${at}.title must be a string")
        (if !(s ? subtitle) || builtins.isString s.subtitle then true else fail "${at}.subtitle must be a string")
        (ms "hold" 0 3000)
        (ms "lift" 300 5000)
        (if !(s ? sound) || (builtins.isString s.sound && (theme.assets.sounds or { }) ? ${s.sound})
        then true else fail "${at}.sound must name an entry in assets.sounds")
      ]
    )
    ++ lib.optionals ((theme.widgets.plates.settings or null) != null) (
      # Surface plates (D-076): nine-sliced pieces under assets/ behind
      # the shell's panels (`panel`) and toasts (`toast`), or "window"
      # for the window frame: chrome border and ornaments corners (D-081).
      let
        at = "widgets.plates.settings";
        s = theme.widgets.plates.settings;
        piece = key: p:
          if p == "window" then true
          else if !(builtins.isAttrs p) then fail "${at}.${key} must be { src; slice; } or \"window\""
          else
            builtins.seq (checkClosed "${at}.${key}" [ "src" "slice" ] p) (
              if !(builtins.isString (p.src or null) && builtins.pathExists (themeDir + "/assets/${p.src}"))
              then fail "${at}.${key}.src must name a file under assets/, got ${builtins.toJSON (p.src or null)}"
              else if !(builtins.isList (p.slice or null) && builtins.length p.slice == 4
              && lib.all (n: builtins.isInt n && n >= 0) p.slice)
              then fail "${at}.${key}.slice must be four non-negative ints [left top right bottom]"
              else true
            );
      in
      [ (checkClosed at [ "panel" "toast" ] s) ]
      ++ lib.mapAttrsToList piece s
    )
    ++ lib.optionals ((theme.widgets.ornaments.settings or null) != null) (
      # Window ornaments (D-074): the top-left corner art (an .svg under
      # assets/, mirrored by the shell), its size, how far the frame's
      # outer corner sits from the art's top-left, and the opacity on
      # unfocused windows.
      let
        at = "widgets.ornaments.settings";
        s = theme.widgets.ornaments.settings;
        size = s.size or 48;
      in
      [
        (checkClosed at [ "corner" "size" "reach" "inactive" ] s)
        (if builtins.isString (s.corner or null) && lib.hasSuffix ".svg" s.corner
        && builtins.pathExists (themeDir + "/assets/${s.corner}") then true
        else fail "${at}.corner must name an .svg under assets/, got ${builtins.toJSON (s.corner or null)}")
        (if builtins.isInt size && size >= 16 && size <= 96 then true
        else fail "${at}.size must be an int from 16 to 96")
        (if !(s ? reach) || (builtins.isInt s.reach && s.reach >= 0 && builtins.isInt size && s.reach * 2 <= size) then true
        else fail "${at}.reach must be an int from 0 to half of size")
        (if !(s ? inactive) || ((builtins.isFloat s.inactive || builtins.isInt s.inactive)
        && s.inactive >= 0 && s.inactive <= 1) then true
        else fail "${at}.inactive must be a number from 0 to 1")
      ]
    )
    ++ lib.optionals ((theme.widgets.clock.settings or null) != null) (
      let
        at = "widgets.clock.settings";
        s = theme.widgets.clock.settings;
      in
      [
        (checkClosed at [ "showDate" "layout" ] s)
        (if builtins.isBool (s.showDate or true) then true else fail "${at}.showDate must be a bool")
        (if builtins.elem (s.layout or "stacked") [ "stacked" "inline" ] then true
        else fail "${at}.layout must be stacked or inline")
      ]
    )
    ++ lib.optionals ((theme.widgets.bar.settings or null) != null) (
      # Bar frame (D-063): the style, nine-sliced frame pieces and end
      # caps. Pieces are files under assets/; actions are the runtime's
      # closed set; glow colours are token refs (L-005).
      let
        at = "widgets.bar.settings";
        s = theme.widgets.bar.settings;
        asset = key: v:
          if builtins.isString v && builtins.pathExists (themeDir + "/assets/${v}") then true
          else fail "${key} must name a file under assets/, got ${builtins.toJSON v}";
        piece = key: p:
          builtins.seq (checkClosed "${at}.frame.${key}" [ "src" "slice" ] p) (
            if !(builtins.seq (asset "${at}.frame.${key}.src" (p.src or null)) true) then false
            else if !(builtins.isList (p.slice or null) && builtins.length p.slice == 4
            && lib.all (n: builtins.isInt n && n >= 0) p.slice)
            then fail "${at}.frame.${key}.slice must be four non-negative ints [left top right bottom]"
            else true
          );
        cap = key: c:
          builtins.seq (checkClosed "${at}.caps.${key}" [ "action" "plate" "emblem" "turn" ] c) (
            if !(builtins.elem (c.action or null) [ "launcher" "dashboard" "power" ])
            then fail "${at}.caps.${key}.action must be one of launcher, dashboard, power"
            else if c ? plate && !(builtins.seq (asset "${at}.caps.${key}.plate" c.plate) true) then false
            else if c ? emblem && !builtins.isString c.emblem then fail "${at}.caps.${key}.emblem must be a string"
            else if c ? turn && !(builtins.isInt c.turn && c.turn >= -90 && c.turn <= 90)
            then fail "${at}.caps.${key}.turn must be an int from -90 to 90"
            else true
          );
        ref = key: v:
          if builtins.isString v && builtins.match "(bg|fg|accent|state)[.][a-z0-9]+" v != null then true
          else fail "${at}.glow.${key} must be a colour token ref, got ${builtins.toJSON v}";
      in
      [
        (checkClosed at [ "style" "frame" "caps" "glow" "inset" "plaquePad" ] s)
        (if !(s ? inset) || (builtins.isInt s.inset && s.inset >= 0 && s.inset <= 16) then true
        else fail "${at}.inset must be an int from 0 to 16")
        (if !(s ? plaquePad) || (builtins.isInt s.plaquePad && s.plaquePad >= 0 && s.plaquePad <= 24) then true
        else fail "${at}.plaquePad must be an int from 0 to 24")
        (if builtins.elem (s.style or "floating") [ "floating" "rail" ] then true
        else fail "${at}.style must be floating or rail")
      ]
      ++ lib.optionals (s ? frame) (
        [ (checkClosed "${at}.frame" [ "body" "plaque" "popout" ] s.frame) ]
        ++ lib.mapAttrsToList piece s.frame
      )
      ++ lib.optionals (s ? caps) (
        [ (checkClosed "${at}.caps" [ "start" "end" ] s.caps) ]
        ++ lib.mapAttrsToList cap s.caps
      )
      ++ lib.optionals (s ? glow) (
        [ (checkClosed "${at}.glow" [ "rest" "hover" ] s.glow) ]
        ++ lib.mapAttrsToList ref s.glow
      )
    )
    ++ map
      (plugin: checkClosed "plugins entry"
        [ "id" "source" "entry" "region" "priority" "services" "layout" "unloadWhenClosed" ]
        plugin)
      (theme.plugins or [ ])
    ++ lib.optionals (theme ? integration) (
      [
        (checkClosed "integration"
          [ "gtk" "qt" "cursor" "fonts" "boot" "tools" ]
          theme.integration)
      ]
      ++ lib.optionals (theme.integration ? boot) (
        let
          boot = theme.integration.boot;
          inherit (boot) menu;
          fileIn = at: set: key: suffixes:
            let v = set.${key}; in
            if !(builtins.isPath v) then fail "${at}.${key} must be a path"
            else if !(builtins.pathExists v) then fail "${at}.${key} does not exist: ${toString v}"
            else if !(lib.any (s: lib.hasSuffix s (lib.toLower (toString v))) suffixes)
            then fail "${at}.${key} must be one of ${lib.concatStringsSep " " suffixes}"
            else true;
          file = fileIn "integration.boot" boot;
        in
        [
          (checkClosed "integration.boot" [ "sigil" "promptLabel" "font" "menu" ] boot)
          (if boot ? sigil then file "sigil" [ ".svg" ] else fail "integration.boot.sigil is required")
          (if !(boot ? promptLabel) || builtins.isString boot.promptLabel then true
          else fail "integration.boot.promptLabel must be a string")
        ]
        ++ lib.optional (boot ? font) (file "font" [ ".ttf" ".otf" ])
        # Boot menu (D-092): Limine reads JPEG, PNG and BMP wallpapers.
        ++ lib.optionals (boot ? menu) (
          [ (checkClosed "integration.boot.menu" [ "wallpaper" "branding" ] menu) ]
          ++ lib.optional (menu ? wallpaper)
            (fileIn "integration.boot.menu" menu "wallpaper" [ ".jpg" ".jpeg" ".png" ])
          ++ lib.optional (menu ? branding)
            (if builtins.isString menu.branding then true
            else fail "integration.boot.menu.branding must be a string")
        )
      )
      ++ lib.optionals (theme.integration ? gtk) [
        (checkClosed "integration.gtk" [ "theme" "iconTheme" ] theme.integration.gtk)
      ]
      ++ lib.optionals (theme.integration ? qt) [
        (checkClosed "integration.qt" [ "style" ] theme.integration.qt)
      ]
      ++ lib.optionals (theme.integration ? cursor) (
        let
          cursor = theme.integration.cursor;
          inherit (import ./_cursor-theme.nix { inherit pkgs lib; }) aliases required;
          shapeCheck = shape: s:
            let at = "integration.cursor.shapes.${shape}"; in
            if !(aliases ? ${shape}) then fail "${at} is not a known shape (${lib.concatStringsSep " " (lib.attrNames aliases)})"
            else if !(checkClosed at [ "svg" "hotspot" ] s) then false
            else if !(s ? svg) || !(builtins.isPath s.svg) || !(builtins.pathExists s.svg) || !(lib.hasSuffix ".svg" (toString s.svg))
            then fail "${at}.svg must be an existing .svg path"
            else if !(s ? hotspot) || !(builtins.isList s.hotspot) || builtins.length s.hotspot != 2
            || !(lib.all (v: (builtins.isInt v || builtins.isFloat v) && v >= 0 && v <= 1) s.hotspot)
            then fail "${at}.hotspot must be [ x y ] fractions in 0..1"
            else true;
        in
        [
          (checkClosed "integration.cursor" [ "name" "size" "shapes" ] cursor)
          (if builtins.isString (cursor.name or null) && builtins.match "[A-Za-z0-9._-]+" cursor.name != null then true
          else fail "integration.cursor.name must match [A-Za-z0-9._-]+")
          (if builtins.isInt (cursor.size or null) && cursor.size >= 8 && cursor.size <= 128 then true
          else fail "integration.cursor.size must be an integer in 8..128")
        ]
        ++ lib.optionals (cursor ? shapes) (
          [
            (if builtins.isAttrs cursor.shapes then true else fail "integration.cursor.shapes must be an attrset")
            (
              let missing = lib.subtractLists (lib.attrNames cursor.shapes) required; in
              if missing == [ ] then true
              else fail "integration.cursor.shapes is missing ${lib.concatStringsSep ", " missing}"
            )
          ]
          ++ lib.mapAttrsToList shapeCheck cursor.shapes
        )
      )
      ++ lib.optionals (theme.integration ? tools) [
        (
          let known = [ "btop" "bat" "yazi" "cava" "vscode" "spotify" "discord" "zen" ]; v = theme.integration.tools; in
          if builtins.isList v && lib.all (x: lib.elem x known) v then true
          else fail "integration.tools must be a list drawn from [${lib.concatStringsSep " " known}], got ${builtins.toJSON v}"
        )
      ]
      ++ lib.optionals (theme.integration ? fonts) [
        (checkClosed "integration.fonts" [ "packages" ] theme.integration.fonts)
      ]
    );

  descriptorChecks =
    lib.mapAttrsToList
      (id: descriptor: checkUnloadWhenClosed "widgets.${id}" descriptor)
      (theme.widgets or { })
    ++ map
      (plugin: checkUnloadWhenClosed "plugins entry" plugin)
      (theme.plugins or [ ]);

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

  requireBoundedMetric = path:
    let value = get path tokens; in
    if value >= 0 && value <= 512 then true
    else fail "tokens.${lib.concatStringsSep "." path} must be between 0 and 512";

  metricRangeChecks =
    map (name: requireBoundedMetric [ "metrics" "radius" name ])
      [ "small" "medium" "large" ]
    ++ map (name: requireBoundedMetric [ "metrics" "space" name ])
      [ "xs" "sm" "md" "lg" ]
    ++ map (name: requirePositive [ "metrics" "workspaces" name ])
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
    ]
    ++ lib.optionals (tokens.motion ? compositor) (
      let c = tokens.motion.compositor; in
      [ (checkClosed "tokens.motion.compositor" (lib.attrNames compositorStyles) c) ]
      ++ lib.mapAttrsToList
        (key: pattern:
          if !(c ? ${key}) || (builtins.isString c.${key} && builtins.match pattern c.${key} != null)
          then true
          else fail "tokens.motion.compositor.${key} must match ${pattern}, got ${builtins.toJSON c.${key}}")
        compositorStyles
    );

  # Hyprland animation styles a theme may pick (D-047). Timings are not
  # here: the adapter derives speeds and curves from durations/easings.
  # The rice-hyprland-theme adapter re-checks the same patterns.
  compositorStyles = {
    windowsIn = "(slide|gnomed|popin( [0-9]{1,2}%)?)";
    windowsOut = "(slide|gnomed|popin( [0-9]{1,2}%)?)";
    workspaces = "(slide|slidevert|fade|slidefade( [0-9]{1,2}%)?|slidefadevert( [0-9]{1,2}%)?)";
    layers = "(slide|fade|popin( [0-9]{1,2}%)?)";
    # Gradient sweep on focus change (D-049); never "loop" (L-007).
    borderSweep = "once";
    # Border colour changes snap instead of fading (D-073).
    borderFade = "off";
  };

  # Window chrome (D-049): border gradient and group-bar colours, all
  # colour token refs (L-005); D-072 adds the inactive gradient, border
  # width, corner rounding and a drop shadow. The adapter re-checks the
  # same shapes.
  chromeChecks = lib.optionals (tokens ? chrome) (
    let
      c = tokens.chrome;
      gradient = path: v:
        if builtins.isList v && builtins.length v >= 1 && builtins.length v <= 4 && lib.all isTokenRef v then true
        else fail "${path} must be a list of 1-4 colour token refs like \"accent.primary\" (L-005), got ${builtins.toJSON v}";
      ref = path: v:
        if isTokenRef v then true
        else fail "${path} must be a colour token ref like \"fg.primary\" (L-005), got ${builtins.toJSON v}";
    in
    [ (checkClosed "tokens.chrome" [ "border" "groupbar" "rounding" "shadow" ] c) ]
    ++ lib.optionals (c ? border) [
      (checkClosed "tokens.chrome.border" [ "active" "inactive" "angle" "width" ] c.border)
      (gradient "tokens.chrome.border.active" (c.border.active or null))
      (if builtins.isInt (c.border.angle or 0) && (c.border.angle or 0) >= 0 && (c.border.angle or 0) < 360 then true
      else fail "tokens.chrome.border.angle must be an integer in 0..359")
      (if !(c.border ? width) || (builtins.isInt c.border.width && c.border.width >= 1 && c.border.width <= 8) then true
      else fail "tokens.chrome.border.width must be an integer in 1..8")
    ]
    ++ lib.optional (c ? border.inactive) (gradient "tokens.chrome.border.inactive" c.border.inactive)
    ++ lib.optional (c ? rounding && !(builtins.isInt c.rounding && c.rounding >= 0 && c.rounding <= 32))
      (fail "tokens.chrome.rounding must be an integer in 0..32")
    ++ lib.optionals (c ? shadow) (
      let
        sh = c.shadow;
        int = key: lo: hi:
          if !(sh ? ${key}) || (builtins.isInt sh.${key} && sh.${key} >= lo && sh.${key} <= hi) then true
          else fail "tokens.chrome.shadow.${key} must be an integer in ${toString lo}..${toString hi}";
      in
      [
        (checkClosed "tokens.chrome.shadow" [ "color" "range" "power" "offset" ] sh)
        (int "range" 0 64)
        (int "power" 1 4)
        (if !(sh ? offset) || (builtins.isList sh.offset && builtins.length sh.offset == 2
        && lib.all (n: builtins.isInt n && n >= -32 && n <= 32) sh.offset) then true
        else fail "tokens.chrome.shadow.offset must be two integers in -32..32 [x y]")
      ]
      ++ lib.optional (sh ? color) (ref "tokens.chrome.shadow.color" sh.color)
    )
    ++ lib.optionals (c ? groupbar) (
      let g = c.groupbar; in
      [
        (checkClosed "tokens.chrome.groupbar" [ "active" "inactive" "text" "textInactive" "font" ] g)
        (if lib.elem (g.font or "sans") [ "display" "sans" "mono" ] then true
        else fail "tokens.chrome.groupbar.font must be one of [display sans mono]")
      ]
      ++ lib.optional (g ? active) (gradient "tokens.chrome.groupbar.active" g.active)
      ++ lib.optional (g ? inactive) (gradient "tokens.chrome.groupbar.inactive" g.inactive)
      ++ lib.optional (g ? text) (ref "tokens.chrome.groupbar.text" g.text)
      ++ lib.optional (g ? textInactive) (ref "tokens.chrome.groupbar.textInactive" g.textInactive)
    )
  );

  effectTypes = [ "fog" "particles" "vignette" "rain" ];
  # Sky conditions a preset may key on (D-046); the runtime's
  # SkyController is the only source of these names.
  skyConditions = [ "fullMoon" "rain" "fog" ];
  # Tints are color TOKEN REFS (L-005: effects derive from tokens,
  # never literal colors): "<bg|fg|accent|state>.<key>". The reference
  # path is relative to tokens.colors and must resolve there.
  isTokenRef = v:
    builtins.isString v
    && builtins.match "(bg|fg|accent|state)\\.[a-zA-Z0-9]+" v != null
    && lib.hasAttrByPath (lib.splitString "." v) tokens.colors;
  layerCheck = l:
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
    else true;
  # Conditional presets (D-046): while a sky condition holds, retint
  # layers by type, scale their strength, and/or add layers (all still
  # clamped by the runtime's budgets).
  presetCheck = p:
    if !builtins.isAttrs p
    then fail "tokens.effects presets must be attrsets"
    else if !(checkClosed "tokens.effects preset" [ "when" "window" "tints" "strength" "layers" ] p)
    then false
    else if !(lib.elem (p.when or null) skyConditions)
    then fail "tokens.effects preset when must be one of [${lib.concatStringsSep " " skyConditions}], got ${builtins.toJSON (p.when or null)}"
    else if p ? window && !(builtins.isInt p.window || builtins.isFloat p.window)
    then fail "tokens.effects preset window must be a number of days"
    else if !lib.all (t: lib.elem t effectTypes && isTokenRef p.tints.${t}) (lib.attrNames (p.tints or { }))
    then fail "tokens.effects preset tints must map layer types to color token refs, got ${builtins.toJSON (p.tints or null)}"
    else if !lib.all (t: lib.elem t effectTypes && (builtins.isInt p.strength.${t} || builtins.isFloat p.strength.${t})) (lib.attrNames (p.strength or { }))
    then fail "tokens.effects preset strength must map layer types to numbers, got ${builtins.toJSON (p.strength or null)}"
    else if !builtins.isList (p.layers or [ ])
    then fail "tokens.effects preset layers must be a list"
    else lib.all layerCheck (p.layers or [ ]);
  effectChecks =
    let
      layers =
        if tokens ? effects
        then tokens.effects.layers or (fail "missing tokens.effects.layers")
        else [ ];
      presets = (tokens.effects or { }).presets or [ ];
    in
    if !builtins.isList layers
    then fail "tokens.effects.layers must be a list"
    else if !builtins.isList presets
    then fail "tokens.effects.presets must be a list"
    else map layerCheck layers ++ map presetCheck presets;

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

  # integration.boot is rebuild-time only (D-044): the boot module reads
  # it from _theme.nix, so its paths never land in the runtime manifest.
  # Cursor shapes are build inputs too (D-048); the manifest keeps the
  # name and size the live adapter applies.
  integration = removeAttrs (theme.integration or { }) [ "boot" ]
    // lib.optionalAttrs (theme ? integration.cursor) {
    cursor = removeAttrs theme.integration.cursor [ "shapes" ];
  };

  manifest = removeAttrs theme [ "integration" ] // lib.optionalAttrs (integration != { }) { inherit integration; } // {
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

  checks = schemaChecks ++ descriptorChecks ++ tokenChecks ++ metricRangeChecks ++ metaChecks ++ iconChecks ++ soundChecks ++ rasterChecks
    ++ motionExtraChecks ++ effectChecks ++ chromeChecks ++ pluginChecks;
in
{
  inherit manifest;
  validated = builtins.deepSeq checks true;
  json = builtins.deepSeq checks
    (pkgs.writeText "rice-manifest-${themeName}.json" (builtins.toJSON manifest));
}
