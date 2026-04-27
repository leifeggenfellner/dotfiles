_: {
  flake.nixosModules.config-monitors =
    { lib, ... }:
    let
      monitorSubmodule = lib.types.submodule {
        options = {
          desc = lib.mkOption {
            type = lib.types.str;
            description = "Monitor description string from hyprctl (e.g. 'HP Inc. HP 527pu 1H35421YT0')";
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Connector name override (e.g. 'eDP-1'). If empty, detected at runtime via desc.";
          };
          resolution = lib.mkOption {
            type = lib.types.str;
            default = "preferred";
            description = "Resolution string (e.g. '2560x1440@60')";
          };
          position = lib.mkOption {
            type = lib.types.str;
            default = "auto";
            description = "Position string (e.g. '1920x0')";
          };
          scale = lib.mkOption {
            type = lib.types.str;
            default = "1";
            description = "Scale factor";
          };
        };
      };
    in
    {
      options.environment.desktop.monitors = lib.mkOption {
        type = lib.types.attrsOf monitorSubmodule;
        default = { };
        description = "Named monitor registry. Keys are logical names (e.g. 'laptop', 'work', 'home').";
      };

      options.environment.desktop.lockMonitorPriority = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Ordered list of monitor keys (from environment.desktop.monitors) to prefer for the lock screen. First connected one wins.";
        example = [ "work" "home" "laptop" ];
      };
    };
}
