{ config, lib, pkgs, ... }:

let
  monitorLeft  = "desc:HP Inc. HP E45c G5 CNC50212K0";
  monitorRight = "desc:HP Inc. HP E45c G5 CNC1000000";
  laptop       = "eDP-1";

  workspaceDefs = [
    { id = "1"; name = "code";   monitor = monitorLeft;  }
    { id = "2"; name = "alacritty"; monitor = monitorLeft; }
    { id = "3"; name = "zen";    monitor = monitorRight; }
    { id = "4"; name = "comms";  monitor = monitorRight; }
    { id = "5"; name = "media";  monitor = monitorRight; }
    { id = "6"; name = "vm";     monitor = monitorLeft; }
    { id = "7"; name = "sys";    monitor = monitorLeft; }
    { id = "8"; name = "chat";   monitor = monitorRight; }
    { id = "9"; name = "misc";   monitor = monitorRight; }
  ];

  hyprWorkspaces = builtins.map (ws: "${ws.id}, monitor:${ws.monitor}") workspaceDefs;
in
{
  imports = [
    ./hardware-configuration.nix
    ./power-tuning.nix   # your CPU / TLP tuning module
  ];

  networking.hostName = "shitbox";

  users.users.leif = {
    isNormalUser = true;
    initialHashedPassword = "$7$CU..../....7emauu/nSIai9Z3k.5nme1$6FDaMoeVeQBls.bZ3FsswOVWoeB.ILPtcIAqZh24f54";
    extraGroups = [ "wheel" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [];
  };

  ########################################
  # NVIDIA PRIME Offload Base (Active)
  ########################################
  hardware = {
    graphics.enable = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = true;   # runtime suspend
      open = false;                         # keep proprietary kernel module
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      prime = {
        offload.enable = true;
        offload.enableOffloadCmd = true;    # adds prime-run
        sync.enable = false;                # ensure dGPU not primary
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };
  };

  # Needed for Xwayland / some OpenGL apps
  services.xserver.videoDrivers = [ "nvidia" ];

  ########################################
  # Specialisation: Disable NVIDIA fully
  ########################################
  specialisation.no-nvidia.configuration = {
    boot.blacklistedKernelModules = [
      "nouveau"
      "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm"
    ];
    services.xserver.videoDrivers = [ "modesetting" ];
    # Neutralize hardware.nvidia block if imported elsewhere
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
        "${laptop},1920x1200,2560x1440,1"
        "${monitorLeft},2560x1440,0x0,1"
        "${monitorRight},2560x1440,2560x0,1"
        ",highrr,auto,1"
      ];
      workspace = hyprWorkspaces;
      windowrulev2 = [
        "workspace 1,class:(Code)"
        "workspace 2,class:(Alacritty)"
        "workspace 3,class:(zen)"
        "workspace 4,class:(Slack)"
        "workspace 4,class:(discord)"
        "workspace 5,class:(spotify)"
        "float,class:(pavucontrol)"
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
    glxinfo
  ];
}
