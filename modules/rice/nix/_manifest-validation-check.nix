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
    (setAtPath [ "integration" "custom" ] true cyberpunk)
    (setAtPath [ "integration" "gtk" "custom" ] true cyberpunk)
  ];

  invalidResults = map (evaluates "cyberpunk") invalidThemes
    ++ [
    (evaluates "lotm"
      (setAtPath [ "plugins" ]
        [ ((builtins.head lotm.plugins) // { custom = true; }) ]
        lotm))
  ];
in
assert lib.all (result: result) validThemes;
assert lib.all (result: !result) invalidResults;
pkgs.runCommand "rice-manifest-validation" { } ''
  touch $out
''
