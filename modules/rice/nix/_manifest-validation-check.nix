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

  hyprlandVisual = manifest: {
    activeBorder = manifest.tokens.colors.accent.primary;
    inactiveBorder = manifest.tokens.colors.bg.surface1;
    rounding = manifest.tokens.metrics.radius.medium;
  };

  expectedHyprlandVisuals = {
    cyberpunk = {
      activeBorder = "#00e5ff";
      inactiveBorder = "#1e2940";
      rounding = 4;
    };
    lotm = {
      activeBorder = "#c79a3a";
      inactiveBorder = "#3e3121";
      rounding = 10;
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
  ];
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
pkgs.runCommand "rice-manifest-validation" { } ''
  touch $out
''
