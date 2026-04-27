_: {
  flake.nixosModules.services-nfc =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        libnfc
        ccid
        pcsclite
        pcsc-tools
      ];

      services.pcscd.enable = true;
    };
}
