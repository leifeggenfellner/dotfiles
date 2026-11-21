{ pkgs }:
let
  inherit (pkgs) lib;
  mkThemeManifest = import ./_manifest-lib.nix { inherit pkgs lib; };

  themeDirs = {
    cyberpunk = ../themes/cyberpunk;
    lotm = ../themes/lotm;
  };
  cyberpunk = import (themeDirs.cyberpunk + "/_theme.nix");
  lotm = import (themeDirs.lotm + "/_theme.nix");

  removeAtPath = path: attrs:
    let key = builtins.head path; in
    if builtins.length path == 1
    then removeAttrs attrs [ key ]
    else attrs // { ${key} = removeAtPath (builtins.tail path) attrs.${key}; };

  setAtPath = path: value: attrs:
    lib.recursiveUpdate attrs (lib.setAttrByPath path value);

  evaluates = themeName: theme:
    (builtins.tryEval
      (builtins.deepSeq
        (mkThemeManifest {
          inherit themeName theme;
          themeDir = themeDirs.${themeName};
        }).validated
        true)).success;

  oldSchemaV2 = removeAtPath [ "tokens" "metrics" "dashboard" ]
    (removeAtPath [ "tokens" "metrics" "workspaces" ] cyberpunk);
  oldSchemaV2Manifest = (mkThemeManifest {
    themeName = "cyberpunk";
    themeDir = themeDirs.cyberpunk;
    theme = oldSchemaV2;
  }).manifest;
  expectedMetricDefaults = {
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

  # What rice-hyprland-theme applies (D-047): border colours only;
  # rounding and gaps stay with the generated Hyprland config.
  hyprlandVisual = manifest: {
    activeBorder = manifest.tokens.colors.accent.primary;
    inactiveBorder = manifest.tokens.colors.bg.elevated;
  };

  expectedHyprlandVisuals = {
    cyberpunk = {
      activeBorder = "#00e5ff";
      inactiveBorder = "#141b2b";
    };
    lotm = {
      activeBorder = "#c79a3a";
      inactiveBorder = "#2a211a";
    };
  };

  validThemes =
    lib.mapAttrsToList evaluates { inherit cyberpunk lotm; }
    ++ [
      (evaluates "cyberpunk"
        (setAtPath [ "palette" "custom" "brand" ] "#123456" cyberpunk))
      (evaluates "cyberpunk"
        (setAtPath [ "assets" "art" "custom" "splash" ] "splash.png" cyberpunk))
      (evaluates "cyberpunk"
        (setAtPath [ "assets" "icons" "custom-action" ] "X" cyberpunk))
      (evaluates "cyberpunk"
        (setAtPath [ "widgets" "workspaces" "settings" "customOption" ] true cyberpunk))
      (evaluates "cyberpunk"
        (setAtPath [ "widgets" "workspaces" "unloadWhenClosed" ] false cyberpunk))
      (evaluates "lotm"
        (setAtPath [ "plugins" ]
          [ ((builtins.head lotm.plugins) // { unloadWhenClosed = true; }) ]
          lotm))
      (evaluates "lotm"
        (setAtPath [ "plugins" ]
          [ (removeAttrs (builtins.head lotm.plugins) [ "unloadWhenClosed" ]) ]
          lotm))
      (evaluates "cyberpunk" oldSchemaV2)
      (evaluates "cyberpunk"
        (setAtPath [ "integration" ]
          {
            gtk = { theme = "Adwaita"; iconTheme = "Adwaita"; };
            qt.style = "adwaita";
            cursor = { name = "default"; size = 24; };
            fonts.packages = [ ];
          }
          cyberpunk))
    ];

  invalidThemes = [
    (setAtPath [ "tokens" "colors" "accent" "primary" ] "not-a-color" cyberpunk)
    (removeAtPath [ "tokens" "typography" "weights" "regular" ] cyberpunk)
    (removeAtPath [ "tokens" "motion" "easings" "standard" ] cyberpunk)
    (removeAtPath [ "tokens" "motion" "intensity" ] cyberpunk)
    (removeAtPath [ "tokens" "motion" "ambient" ] cyberpunk)
    (removeAtPath [ "tokens" "motion" "enabled" ] cyberpunk)
    (removeAtPath [ "meta" "displayName" ] cyberpunk)
    (setAtPath [ "meta" "version" ] 1 cyberpunk)
    (setAtPath [ "meta" "schemaVersion" ] "2" cyberpunk)
    (setAtPath [ "meta" "schemaVersion" ] 3 cyberpunk)
    (setAtPath [ "unknownTopLevel" ] true cyberpunk)
    (setAtPath [ "meta" "preview" ] "preview.png" cyberpunk)
    (setAtPath [ "tokens" "custom" ] true cyberpunk)
    (setAtPath [ "tokens" "colors" "custom" ] "#123456" cyberpunk)
    (setAtPath [ "tokens" "colors" "accent" "glow" ] "#123456" cyberpunk)
    (setAtPath [ "tokens" "typography" "families" "ui" ] "Sans" cyberpunk)
    (setAtPath [ "tokens" "metrics" "bar" "blur" ] 8 cyberpunk)
    (setAtPath [ "tokens" "metrics" "radius" "medium" ] (-1) cyberpunk)
    (setAtPath [ "tokens" "metrics" "radius" "medium" ] 513 cyberpunk)
    (setAtPath [ "tokens" "metrics" "space" "sm" ] (-1) cyberpunk)
    (setAtPath [ "tokens" "metrics" "space" "md" ] 513 cyberpunk)
    (removeAtPath [ "tokens" "metrics" "workspaces" "slotSize" ] cyberpunk)
    (setAtPath [ "tokens" "metrics" "workspaces" "custom" ] 8 cyberpunk)
    (setAtPath [ "tokens" "metrics" "workspaces" "slotSize" ] 0 cyberpunk)
    (setAtPath [ "tokens" "metrics" "workspaces" "iconSize" ] 31 cyberpunk)
    (setAtPath [ "tokens" "metrics" "workspaces" "iconSourceSize" ] 23 cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "sidebarRatio" ] "0.46" cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "columnCount" ] 0 cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "sidebarRatio" ] 0 cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "sidebarRatio" ] 1 cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "sidebarMinWidth" ] 561 cyberpunk)
    (setAtPath [ "tokens" "metrics" "dashboard" "compactBreakpoint" ] 811 cyberpunk)
    (setAtPath [ "tokens" "motion" "durations" "instant" ] 0 cyberpunk)
    (setAtPath [ "tokens" "motion" "easings" "spring" ] "OutBack" cyberpunk)
    (setAtPath [ "tokens" "effects" "custom" ] true cyberpunk)
    (setAtPath [ "tokens" "effects" ] { } cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [{ type = "fog"; opacity = 0.1; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [{ type = "fog"; tint = true; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [{ type = "fog"; tint = "accent.missing"; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [{ type = "fog"; tint = "accent.primary"; shader = "custom.qsb"; }];
      }
      cyberpunk)
    # Compositor motion (D-047).
    (setAtPath [ "tokens" "motion" "compositor" "windowsIn" ] "explode" cyberpunk)
    (setAtPath [ "tokens" "motion" "compositor" "windowsIn" ] "popin 150%" cyberpunk)
    (setAtPath [ "tokens" "motion" "compositor" "speed" ] 4 cyberpunk)
    # Conditional presets (D-046).
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [ ];
        presets = [{ when = "eclipse"; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [ ];
        presets = [{ when = "fullMoon"; tints.fog = "#ff0000"; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [ ];
        presets = [{ when = "rain"; strength.fog = "more"; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [ ];
        presets = [{ when = "rain"; layers = [{ type = "rain"; }]; }];
      }
      cyberpunk)
    (setAtPath [ "tokens" "effects" ]
      {
        layers = [ ];
        presets = [{ when = "fog"; custom = true; }];
      }
      cyberpunk)
    (setAtPath [ "assets" "custom" ] true cyberpunk)
    (setAtPath [ "widgets" "workspaces" "custom" ] true cyberpunk)
    (setAtPath [ "widgets" "workspaces" "unloadWhenClosed" ] "false" cyberpunk)
    (setAtPath [ "integration" "custom" ] true cyberpunk)
    (setAtPath [ "integration" "gtk" "custom" ] true cyberpunk)
  ];

  invalidResults = map (evaluates "cyberpunk") invalidThemes
    ++ [
    (evaluates "lotm"
      (setAtPath [ "plugins" ]
        [ ((builtins.head lotm.plugins) // { custom = true; }) ]
        lotm))
    (evaluates "lotm"
      (setAtPath [ "plugins" ]
        [ ((builtins.head lotm.plugins) // { unloadWhenClosed = "false"; }) ]
        lotm))
    # Terminal tools (D-051).
    (evaluates "lotm" (setAtPath [ "integration" "tools" ] [ "htop" ] lotm))
    (evaluates "lotm" (setAtPath [ "integration" "tools" ] "btop" lotm))
    # Window chrome (D-049).
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "active" ] [ "#c79a3a" ] lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "active" ] [ "accent.missing" ] lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "active" ] [ "accent.primary" "accent.primary" "accent.primary" "accent.primary" "accent.primary" ] lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "angle" ] 400 lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "groupbar" "font" ] "Cinzel" lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "groupbar" "text" ] [ "fg.primary" ] lotm))
    # Square gilt windows (D-072).
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "rounding" ] 40 lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "width" ] 0 lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "border" "inactive" ] [ "#2a211a" ] lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "shadow" "blur" ] 4 lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "shadow" "color" ] "#000000" lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "shadow" "offset" ] [ 3 ] lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "shadow" "power" ] 9 lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "glow" ] { } lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "motion" "compositor" "borderSweep" ] "loop" lotm))
    # Solid focus border (D-073).
    (evaluates "lotm" (setAtPath [ "tokens" "motion" "compositor" "borderFade" ] "slow" lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "motion" "compositor" "borderFade" ] false lotm))
    # Awakening (D-053, D-085).
    (evaluates "lotm" (setAtPath [ "widgets" "awakening" "settings" "backdrop" ] "boot/missing.png" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "awakening" "settings" "backdrop" ] "boot/hall.mp4" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "awakening" "settings" "hold" ] 9000 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "awakening" "settings" "veil" ] "black" lotm))
    # Boot ascent (D-085).
    (evaluates "lotm" (setAtPath [ "integration" "boot" "ascent" "climb" ] ./missing-climb.png lotm))
    (evaluates "lotm" (setAtPath [ "integration" "boot" "ascent" "fog" ] ../themes/lotm/assets/boot/hall.png lotm))
    (evaluates "lotm" (setAtPath [ "integration" "boot" "ascent" ] "castle" lotm))
    (evaluates "lotm" (setAtPath [ "integration" "boot" "ascent" "hall" ] ../themes/lotm/assets/pathways/fool.svg lotm))
    # Surface plates (D-076, D-081).
    (evaluates "lotm" (setAtPath [ "widgets" "plates" "settings" "popout" ] "window" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "plates" "settings" "toast" ] { src = "bar/missing.svg"; slice = [ 1 1 1 1 ]; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "plates" "settings" "toast" ] { src = "bar/rail.svg"; slice = [ 10 10 10 ]; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "plates" "settings" "toast" ] "bar/rail.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "plates" "settings" "panel" ] "door" lotm))
    # Toast ceremony (D-082).
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "ceremony" "wax" ] "#8a3b3b" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "ceremony" "seal" ] "pathways/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "ceremony" "hand" ] "" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "ceremony" "smoke" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "ceremony" ] "letter" lotm))
    # Window ornaments (D-074).
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "corner" ] "chrome/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "corner" ] "bar/rail.png" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "size" ] 8 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "reach" ] 30 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "inactive" ] 1.5 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "ornaments" "settings" "glint" ] true lotm))
    # Daily accent (D-054).
    (evaluates "lotm" (setAtPath [ "widgets" "dailyAccent" "settings" "record" ] "tarotDraw.daily" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "dailyAccent" "settings" "catalog" ] "widgets.tarotDraw.settings.missing" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "dailyAccent" "settings" "custom" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tarotDraw" "settings" "cards" ] [{ id = "fool"; accent = "gold"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tarotDraw" "settings" "cards" ] [{ id = "fool"; accent = "#aaa3cf"; sigil = "pathways/missing.svg"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tarotDraw" "settings" "cards" ] [{ id = "a b"; accent = "#aaa3cf"; }] lotm))
    # Notification personas (D-056).
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] { apps = [ "discord" ]; label = "x"; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] [{ apps = [ ]; label = "x"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] [{ apps = [ "discord" ]; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] [{ apps = [ "discord" ]; label = "x"; variant = "scroll"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] [{ apps = [ "discord" ]; label = "x"; sound = "missing"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "correspondence" "settings" "personas" ] [{ apps = [ "discord" ]; label = "x"; colour = "red"; }] lotm))
    # Polkit prompt (D-062).
    (evaluates "lotm" (setAtPath [ "widgets" "polkit" "settings" "titel" ] "x" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "polkit" "settings" "sound" ] "missing" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "polkit" "settings" "title" ] 42 lotm))
    # Bar frame (D-063).
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "shape" ] "pill" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "style" ] "pill" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "rule" ] { src = "bar/rail.svg"; slice = [ 0 0 0 0 ]; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "body" "src" ] "bar/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "body" "slice" ] 24 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "plaque" "slice" ] [ 8 8 8 (-1) ] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "caps" "start" "action" ] "terminal" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "caps" "start" "spin" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "caps" "start" "turn" ] 360 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "caps" "end" "plate" ] "bar/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "caps" "middle" ] { action = "power"; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "glow" "hover" ] "#ffaa00" lotm))
    # Rail inset and plaque padding (D-071).
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "inset" ] (-1) lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "inset" ] "4" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "plaquePad" ] 40 lotm))
    # Hinged popout plate (D-070).
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "popout" "src" ] "bar/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "bar" "settings" "frame" "popout" "hinge" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "clock" "settings" "layout" ] "row" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "clock" "settings" "format" ] "HH:mm" lotm))
    # Instruments and tray hatch (D-064).
    (evaluates "lotm" (setAtPath [ "widgets" "system" "settings" "wifiStyle" ] "mast" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "system" "settings" "lowBattery" ] 15 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "system" "settings" "bluetooth" ] "on" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "system" "settings" "batteryGauge" ] { full = 0.9; empty = 0.1; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "system" "settings" "batteryGauge" "left" ] 0.1 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "media" "settings" "marquee" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "media" "settings" "hideIdle" ] "yes" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "monitor-profile" "settings" "showLabel" ] 0 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tray" "settings" "maxInline" ] 0 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tray" "settings" "tone" ] "grayscale" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "tray" "settings" "allow" ] [ "steam" ] lotm))
    # Sigil bezels (D-065).
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "bezel" "glow" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "bezel" "plate" ] "bar/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "bezel" "needle" ] 3 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "bezel" "urgent" ] "#8a3b3b" lotm))
    # Workspace carousel (D-067).
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "tilt" ] 35 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "card" "src" ] "bar/missing.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "nameplate" "slice" ] [ 8 8 8 ] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "card" ] "bar/card.svg" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "copy" "few" ] "{n} windows" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "copy" "many" ] 3 lotm))
    # Carousel captures (D-068).
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "capture" "live" ] true lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "capture" "tint" ] "#704214" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "capture" "strength" ] 1.5 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "workspaces" "settings" "carousel" "capture" ] true lotm))
    # Browser new-tab page (D-060).
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "title" ] 42 lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "epigraphs" ] "widgets.epigraph.settings.missing" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "labels" ] { weather = "x"; headline = "y"; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "daily" "record" ] "tarotDraw.daily" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "daily" "catalog" ] "widgets.tarotDraw.settings.missing" lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "newtab" "settings" "edition" ] "Evening" lotm))
    # Sound bed layers (D-058).
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] { sound = "bed-rain"; } lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "missing"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "bed-rain"; volume = 1.5; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "bed-rain"; volume = "loud"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "bed-rain"; when = "snow"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "bed-rain"; mood = "nowhere"; }] lotm))
    (evaluates "lotm" (setAtPath [ "widgets" "soundscape" "settings" "layers" ] [{ sound = "bed-rain"; pan = 0.5; }] lotm))
    # Cursor (D-048).
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "name" ] "lotm quill" lotm))
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "size" ] 4 lotm))
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "custom" ] true lotm))
    (evaluates "lotm" (removeAtPath [ "integration" "cursor" "shapes" "pointer" ] lotm))
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "shapes" "zoom" ] lotm.integration.cursor.shapes.move lotm))
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "shapes" "move" "hotspot" ] [ 0.5 1.5 ] lotm))
    (evaluates "lotm" (setAtPath [ "integration" "cursor" "shapes" "move" "svg" ] ../themes/lotm/assets/preview.png lotm))
  ];

  lotmManifest = (mkThemeManifest { themeName = "lotm"; themeDir = themeDirs.lotm; }).manifest;
in
assert lib.all (result: result) validThemes;
assert oldSchemaV2Manifest.tokens.metrics.workspaces == expectedMetricDefaults.workspaces;
assert oldSchemaV2Manifest.tokens.metrics.dashboard == expectedMetricDefaults.dashboard;
assert hyprlandVisual (mkThemeManifest {
  themeName = "cyberpunk";
  themeDir = themeDirs.cyberpunk;
}).manifest == expectedHyprlandVisuals.cyberpunk;
assert hyprlandVisual (mkThemeManifest {
  themeName = "lotm";
  themeDir = themeDirs.lotm;
}).manifest == expectedHyprlandVisuals.lotm;
assert lib.all (result: !result) invalidResults;
# Cursor shapes are build inputs; the runtime manifest keeps name + size.
assert lotmManifest.integration.cursor == { name = "lotm-quill"; size = 24; };
assert !(cyberpunk ? integration.cursor);
pkgs.runCommand "rice-manifest-validation" { } ''
  touch $out
''
