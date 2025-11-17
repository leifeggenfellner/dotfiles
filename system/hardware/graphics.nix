{ config, pkgs, ... }:
{
  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;

      # Enable runtime PM so the GPU can suspend (needs proprietary driver)
      powerManagement.enable = true;
      powerManagement.finegrained = true; # NVreg_DynamicPowerManagement=0x02

      open = false; # Keep proprietary kernel module (change to true if you test open modules)
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        # Turn OFF sync, turn ON offload:
        sync.enable = false;
        offload.enable = true;
        offload.enableOffloadCmd = true; # Provides 'prime-run'
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # If you rely on Xwayland or X apps:
  services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
  ];
}
