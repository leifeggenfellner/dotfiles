{ lib, osConfig, ... }:
let
  inherit (osConfig.environment.desktop) monitors;
in
{
  program.hyprlock.defaultMonitor = monitors.laptop.name;

  service = lib.mkMerge [
    {
      hypridle = {
        dpms = true;
        suspend = true;
      };
    }
  ];
}
