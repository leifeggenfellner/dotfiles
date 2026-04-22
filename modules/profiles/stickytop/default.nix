{ lib
, ...
}:
{
  imports = [ ../../default.nix ];

  # Built-in 14" eDP panel
  program.hyprlock.defaultMonitor = "eDP-1";

  service = lib.mkMerge [
    {
      hypridle = {
        dpms = true;
        suspend = true;
      };
    }
  ];
}
