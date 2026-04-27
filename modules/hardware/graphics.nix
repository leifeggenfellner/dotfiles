_: {
  flake.nixosModules.hardware-graphics =
    { config, pkgs, ... }:
    {
      hardware = {
        graphics.enable = true;

        nvidia = {
          modesetting.enable = true;

          powerManagement.enable = true;
          powerManagement.finegrained = true;

          open = false;
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;

          prime = {
            sync.enable = false;
            offload.enable = true;
            offload.enableOffloadCmd = true;
            intelBusId = "PCI:0:2:0";
            nvidiaBusId = "PCI:1:0:0";
          };
        };
      };

      services.xserver.videoDrivers = [ "nvidia" ];

      environment.systemPackages = with pkgs; [
        vulkan-tools
        mesa-demos
      ];
    };
}
