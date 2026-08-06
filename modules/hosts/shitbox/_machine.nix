{ config, lib, pkgs, ... }:
{
  imports = [
    ./_hardware-configuration.nix
    ./_power-tuning.nix
  ];

  networking.hostName = "shitbox";

  users.users.leif = {
    isNormalUser = true;
    initialHashedPassword = "$7$CU..../....7emauu/nSIai9Z3k.5nme1$6FDaMoeVeQBls.bZ3FsswOVWoeB.ILPtcIAqZh24f54";
    extraGroups = [ "wheel" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [ ];
  };

  ########################################
  # Intel Arc (default — no NVIDIA)
  ########################################
  hardware.graphics.enable = true;

  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  services.xserver.videoDrivers = [ "modesetting" ];

  ########################################
  # Specialisation:  Enable NVIDIA offload
  ########################################
  specialisation.with-nvidia.configuration = {
    environment.gaming.enable = true;

    boot.blacklistedKernelModules = lib.mkForce [ ];
    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

    hardware.nvidia = {
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

  ########################################
  # Desktop (Hyprland)
  ########################################
  environment.desktop = {
    enable = true;
    windowManager = "hyprland";

    monitors = {
      laptop = { desc = "LG Display 0x0791"; name = "eDP-1"; resolution = "1920x1200@60"; };
      work = { desc = "HP Inc. HP 527pu 1H35421YT0"; resolution = "2560x1440@60"; };
      workRight = { desc = "HP Inc. HP 527pu 1H35421YRD"; resolution = "2560x1440@60"; };
      home = { desc = "Samsung Electric Company C34J79x HTRM900265"; resolution = "3440x1440@60"; };
    };

    lockMonitorPriority = [ "work" "home" "laptop" ];
  };

  rice = {
    enable = true;
    theme = "lotm";
    specialisations.enable = false;
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
