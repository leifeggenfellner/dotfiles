_: {
  flake.homeModules.programs-icue =
    { osConfig, pkgs, lib, ... }:
    {
      config = lib.mkIf osConfig.environment.gaming.enable {
        home = {
          packages = with pkgs; [
            ckb-next
          ];
          persistence."/persist/" = {
            directories = [
              ".config/ckb-next"
            ];
          };
        };
      };
    };
}
