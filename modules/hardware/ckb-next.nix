_: {
  flake.nixosModules.hardware-ckb-next =
    { config, lib, ... }:
    {
      hardware.ckb-next = lib.mkIf config.environment.gaming.enable {
        enable = true;
      };
    };
}
