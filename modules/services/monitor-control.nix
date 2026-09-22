_: {
  flake.homeModules.services-monitor-control =
    { lib, osConfig, pkgs, ... }:
    let
      cfg = osConfig.environment.desktop.monitorControl;
      package = pkgs.callPackage ../scripts/_monitor-control.nix {
        hyprland = osConfig.programs.hyprland.package;
        monitors = osConfig.environment.desktop.monitors;
        monitorControl = cfg;
      };
    in
    {
      config = lib.mkIf cfg.enable {
        home.packages = [ package ];

        systemd.user.services.monitor-control = {
          Unit = {
            Description = "Event-driven Hyprland monitor control";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${package}/bin/monitor-control daemon";
            Restart = "on-failure";
            RestartSec = 1;
            RuntimeDirectory = "monitor-control";
            RuntimeDirectoryMode = "0700";
          };
          Install.WantedBy = [ "graphical-session.target" ];
        };
      };
    };
}
