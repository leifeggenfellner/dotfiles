{ lib
, ...
}:
{
  imports = [ ../../default.nix ];

  # Home modules to load
  program.hyprlock.defaultMonitor = "desc:HP Inc. HP E45c G5 CNC50212K0";

  service = lib.mkMerge [
    {
      hypridle = {
        dpms = false;
        suspend = false;
      };
    }
  ];
}
