{ config, lib, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./power-tuning.nix
  ];

  networking.hostName = "shitbox";

  users.users.leif = {
    isNormalUser = true;
    initialHashedPassword = "$7$CU..../....7emauu/nSIai9Z3k.5nme1$6FDaMoeVeQBls.bZ3FsswOVWoeB.ILPtcIAqZh24f54";
    extraGroups = [ "wheel" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [ ];
  };

  ########################################
  # NVIDIA PRIME Offload Base (Active)
  ########################################
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
        offload.enable = true;
        offload.enableOffloadCmd = true;
        sync.enable = false;
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  ########################################
  # Specialisation:  Disable NVIDIA fully
  ########################################
  specialisation.no-nvidia.configuration = {
    boot.blacklistedKernelModules = [
      "nouveau"
      "nvidia"
      "nvidia_drm"
      "nvidia_modeset"
      "nvidia_uvm"
    ];
    services.xserver.videoDrivers = [ "modesetting" ];
    hardware.nvidia = lib.mkForce { };
  };

  ########################################
  # Desktop (Hyprland)
  ########################################
  environment.desktop = {
    enable = true;
    windowManager = "hyprland";
  };

  programs.hyprland = {
    enable = true;
    settings = {
      monitor = [
        # Laptop on the right
        "eDP-1,1920x1200@60,1920x0,1"

        # Samsung to the left (home)
        "desc:Samsung Electric Company C34J79x HTRM900265,3440x1440@60,0x0,1"

        # Office: HP ultrawide split into two
        "desc:HP Inc. HP E45c G5 CNC50212K0,2560x1440@60,3440x0,1"
        "desc:HP Inc. HP E45c G5 CNC1000000,2560x1440@60,6000x0,1"

        ",preferred,auto,1"
      ];
    };
  };

  system = {
    disks.extraStoreDisk.enable = false;
    bluetooth.enable = true;
  };

  service = {
    blueman.enable = true;
    touchpad.enable = true;
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
  ];
}
