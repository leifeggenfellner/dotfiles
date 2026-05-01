_: {
  flake.nixosModules.hardware-network =
    { lib, ... }:
    {
      networking = {
        networkmanager.enable = true;
        networkmanager.wifi.powersave = false;
        useDHCP = lib.mkDefault true;
        firewall.enable = false;
        extraHosts = ''
          127.0.0.1 tuathaan
          104.199.65.124 ap-gew4.spotify.com
        '';
      };

      boot.kernelModules = [ "iwlwifi" "i915" "iwlmvm" ];

      users.users.leif.extraGroups = [ "networkmanager" ];
    };
}
