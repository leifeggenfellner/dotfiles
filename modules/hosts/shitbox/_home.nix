{ lib, osConfig, ... }:
let
  monitors = osConfig.environment.desktop.monitors;
in
{
  program.hyprlock.defaultMonitor = "desc:${monitors.work.desc}";

  service = lib.mkMerge [
    {
      hypridle = {
        dpms = false;
        suspend = false;
      };
    }
  ];
}
