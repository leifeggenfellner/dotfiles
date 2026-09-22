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
      work = { desc = "HP Inc. HP 527pu"; serial = "1H361409R2"; resolution = "2560x1440@60"; };
      workRight = { desc = "HP Inc. HP 527pu"; serial = "1H361409TR"; resolution = "2560x1440@60"; };
      familyHome = { desc = "Samsung Electric Company C34J79x"; serial = "HTRM900265"; resolution = "3440x1440@60"; };
    };

    monitorControl = {
      enable = true;
      fallbackProfile = "laptop_only";
      profiles = {
        home_office.outputs = [
          { monitor = "workRight"; position = "0x0"; transform = 1; workspaces = [ 2 4 5 ]; }
          { monitor = "work"; position = "1440x0"; primary = true; workspaces = [ 1 3 ]; }
          { monitor = "laptop"; position = "4000x0"; workspaces = [ 6 7 ]; }
        ];
        work.outputs = [
          { monitor = "laptop"; position = "0x0"; workspaces = [ 2 4 6 ]; }
          { monitor = "work"; position = "1920x0"; primary = true; workspaces = [ 1 5 ]; }
          { monitor = "workRight"; position = "4480x0"; workspaces = [ 3 7 ]; }
        ];
        family_home = {
          autoDetect = true;
          outputs = [
            { monitor = "laptop"; position = "0x0"; workspaces = [ 3 4 5 6 ]; }
            { monitor = "familyHome"; position = "1920x0"; primary = true; workspaces = [ 1 2 ]; }
          ];
        };
        laptop_only = {
          autoDetect = true;
          outputs = [
            { monitor = "laptop"; position = "0x0"; primary = true; workspaces = [ 1 2 3 4 5 6 7 8 9 10 ]; }
          ];
        };
      };
      appRoutes = {
        terminal = { class = "^(Alacritty|alacritty|foot)$"; workspace = 2; };
        slack = { class = "^(Slack)$"; workspace = 4; };
        discord = { class = "^(discord)$"; workspace = 4; };
        spotify = { class = "^(spotify)$"; workspace = 5; };
      };
    };

    lockMonitorPriority = [ "work" "familyHome" "laptop" ];
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
