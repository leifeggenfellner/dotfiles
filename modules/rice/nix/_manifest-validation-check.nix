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
    (evaluates "lotm" (setAtPath [ "tokens" "chrome" "shadow" ] { } lotm))
    (evaluates "lotm" (setAtPath [ "tokens" "motion" "compositor" "borderSweep" ] "loop" lotm))
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
