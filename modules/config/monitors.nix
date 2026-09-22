_: {
  flake.nixosModules.config-monitors =
    { config, lib, ... }:
    let
      cfg = config.environment.desktop.monitorControl;
      monitors = config.environment.desktop.monitors;
      connectorType = lib.types.strMatching "([A-Za-z0-9_.:-]+)?";
      modeType = lib.types.strMatching "(preferred|highres|highrr|maxwidth|[0-9]+x[0-9]+@[0-9]+([.][0-9]+)?)";
      positionType = lib.types.strMatching "(auto(-right|-left|-up|-down)?|-?[0-9]+x-?[0-9]+)";
      scaleType = lib.types.strMatching "(auto|[0-9]+([.][0-9]+)?)";
      monitorSubmodule = lib.types.submodule {
        options = {
          desc = lib.mkOption {
            type = lib.types.str;
            description = "Monitor description string from hyprctl (e.g. 'HP Inc. HP 527pu 1H35421YT0')";
          };
          name = lib.mkOption {
            type = connectorType;
            default = "";
            description = "Exact connector for a built-in display (e.g. 'eDP-1'). External displays use serial identity.";
          };
          serial = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Exact serial reported by hyprctl monitors all -j. Empty only for connector-bound built-in displays.";
          };
          resolution = lib.mkOption {
            type = modeType;
            default = "preferred";
            description = "Resolution string (e.g. '2560x1440@60')";
          };
          position = lib.mkOption {
            type = positionType;
            default = "auto";
            description = "Position string (e.g. '1920x0')";
          };
          scale = lib.mkOption {
            type = scaleType;
            default = "1";
            description = "Scale factor";
          };
        };
      };
      profileOutputSubmodule = lib.types.submodule {
        options = {
          monitor = lib.mkOption {
            type = lib.types.str;
            description = "Logical monitor key from environment.desktop.monitors.";
          };
          position = lib.mkOption {
            type = positionType;
            description = "Hyprland output position (for example 1920x0).";
          };
          resolution = lib.mkOption {
            type = lib.types.nullOr modeType;
            default = null;
            description = "Optional profile-specific mode; defaults to the monitor registry mode.";
          };
          scale = lib.mkOption {
            type = lib.types.nullOr scaleType;
            default = null;
            description = "Optional profile-specific scale; defaults to the monitor registry scale.";
          };
          transform = lib.mkOption {
            type = lib.types.ints.between 0 7;
            default = 0;
            description = "Hyprland monitor transform.";
          };
          workspaces = lib.mkOption {
            type = lib.types.listOf lib.types.ints.positive;
            description = "Workspaces assigned to this output; the first is the default.";
          };
          primary = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Preferred focus output when no prior focus can be restored.";
          };
        };
      };
      profileSubmodule = lib.types.submodule {
        options = {
          outputs = lib.mkOption {
            type = lib.types.listOf profileOutputSubmodule;
            description = "Ordered output layout for this profile.";
          };
          autoDetect = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether an exact connected serial set may select this profile automatically.";
          };
        };
      };
      appRouteSubmodule = lib.types.submodule {
        options = {
          class = lib.mkOption {
            type = lib.types.str;
            description = "Hyprland window class regular expression.";
          };
          workspace = lib.mkOption {
            type = lib.types.ints.positive;
            description = "Workspace target for new and existing matching windows.";
          };
        };
      };
      profileMonitorKeys = lib.concatMap
        (profile: map (output: output.monitor) profile.outputs)
        (lib.attrValues cfg.profiles);
      profileWorkspaces = map
        (profile: lib.concatMap (output: output.workspaces) profile.outputs)
        (lib.attrValues cfg.profiles);
      serials = lib.filter (serial: serial != "") (map (monitor: monitor.serial) (lib.attrValues monitors));
      autoSignatures = map
        (profile:
          builtins.toJSON (lib.sort builtins.lessThan (lib.filter (serial: serial != "")
            (map (output: if monitors ? ${output.monitor} then monitors.${output.monitor}.serial else "") profile.outputs))))
        (lib.filter (profile: profile.autoDetect) (lib.attrValues cfg.profiles));
    in
    {
      options = {
        environment.desktop = {
          monitors = lib.mkOption {
            type = lib.types.attrsOf monitorSubmodule;
            default = { };
            description = "Named monitor registry. Keys are logical names (e.g. 'laptop', 'work', 'familyHome').";
          };

          lockMonitorPriority = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Ordered list of monitor keys (from environment.desktop.monitors) to prefer for the lock screen. First connected one wins.";
            example = [ "work" "familyHome" "laptop" ];
          };

          monitorControl = {
            enable = lib.mkEnableOption "the event-driven Hyprland monitor control service";
            profiles = lib.mkOption {
              type = lib.types.attrsOf profileSubmodule;
              default = { };
              description = "Declarative monitor layouts keyed by stable profile name.";
            };
            fallbackProfile = lib.mkOption {
              type = lib.types.str;
              default = "laptop_only";
              description = "Profile used only when automatic selection has no connected or unknown external-output ambiguity.";
            };
            appRoutes = lib.mkOption {
              type = lib.types.attrsOf appRouteSubmodule;
              default = { };
              description = "Application workspace routes owned by monitor control.";
            };
          };
        };
      };

      config.assertions = lib.optionals cfg.enable [
        {
          assertion = lib.all (key: monitors ? ${key}) profileMonitorKeys;
          message = "Every monitor-control profile output must reference environment.desktop.monitors.";
        }
        {
          assertion = cfg.profiles ? ${cfg.fallbackProfile};
          message = "environment.desktop.monitorControl.fallbackProfile must name a declared profile.";
        }
        {
          assertion = lib.all (profile: profile.outputs != [ ] && lib.all (output: output.workspaces != [ ]) profile.outputs) (lib.attrValues cfg.profiles);
          message = "Monitor-control profiles and outputs must declare at least one output and workspace.";
        }
        {
          assertion = lib.all (workspaces: builtins.length workspaces == builtins.length (lib.unique workspaces)) profileWorkspaces;
          message = "A workspace may be assigned only once within each monitor-control profile.";
        }
        {
          assertion = builtins.length serials == builtins.length (lib.unique serials);
          message = "External monitor serials must be unique; descriptions are not monitor identities.";
        }
        {
          assertion = builtins.length autoSignatures == builtins.length (lib.unique autoSignatures);
          message = "Auto-detectable monitor profiles must have unique external serial sets.";
        }
      ];
    };
}
