{ inputs, ... }: {
  flake.homeModules.services-hypridle =
    { lib
    , pkgs
    , config
    , osConfig
    , ...
    }:
    let
      hyprctl = "${pkgs.hyprland}/bin/hyprctl";
      lock = "${pkgs.systemd}/bin/systemctl suspend";

      cfg = config.service.hypridle;
      riceCfg = osConfig.rice or { enable = false; };
      riceIdleHint = value: "${pkgs.quickshell}/bin/quickshell -c rice ipc call ambient setIdleHint ${value} >/dev/null 2>&1 || true";
    in
    {
      options.service.hypridle = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable hypridle";
        };
        dpms = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable dpms, monitor off";
        };
        timeout = lib.mkOption {
          type = lib.types.int;
          default = 3600;
          description = "Idle timeout in seconds before DPMS off and suspend actions.";
        };
        suspend = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable suspend";
        };
        suspendTimer = lib.mkOption {
          type = lib.types.int;
          default = 300;
          description = "Idle timeout in seconds before suspend actions.";
        };
        idleWarning = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Show a rice idle-warning veil before hypridle performs its idle action.";
        };
        idleWarningLeadTime = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Seconds before the primary idle timeout to show the rice idle-warning veil.";
        };
      };

      config = lib.mkIf (cfg.enable && osConfig.environment.desktop.windowManager == "hyprland") {
        services.hypridle = {
          enable = true;
          package = inputs.hypridle.packages.${pkgs.stdenv.hostPlatform.system}.hypridle;

          settings = {
            general = {
              before_sleep_cmd = "${pkgs.systemd}/bin/loginctl lock-session";
              after-sleep-cmd = "${hyprctl} dispatch dpms on";
              lock_cmd = "pgrep hyprlock || lock-screen";
              ignore_dbus_inhibit = true;
            };
            listener =
              (lib.optional ((riceCfg.enable or false) && cfg.idleWarning) {
                timeout = lib.max 1 (cfg.timeout - cfg.idleWarningLeadTime);
                on-timeout = riceIdleHint "on";
                on-resume = riceIdleHint "off";
              })
              ++
              (lib.optional cfg.dpms {
                inherit (cfg) timeout;
                on-timeout = "${hyprctl} dispatch dpms off";
                on-resume = "${hyprctl} dispatch dpms on";
              })
              ++ (lib.optional cfg.suspend {
                timeout = cfg.timeout + cfg.suspendTimer;
                on-timeout = "${lock}";
              });
          };
        };
      };
    };
}
