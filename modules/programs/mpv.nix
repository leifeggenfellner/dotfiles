_: {
  flake.homeModules.programs-mpv =
    { osConfig, lib, ... }:
    {
      programs.mpv.enable = lib.mkIf osConfig.environment.desktop.enable true;
    };
}
