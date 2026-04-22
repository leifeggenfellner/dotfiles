{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./power-tuning.nix
  ];

  networking.hostName = "stickytop";

  users.users.leif = {
    isNormalUser = true;
    initialHashedPassword = "$7$CU..../....7emauu/nSIai9Z3k.5nme1$6FDaMoeVeQBls.bZ3FsswOVWoeB.ILPtcIAqZh24f54";
    extraGroups = [ "wheel" "video" "audio" "plugdev" ];
    openssh.authorizedKeys.keys = [ ];
  };

  ########################################
  # Intel Iris Xe (integrated only)
  ########################################
  hardware.graphics.enable = true;

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
        # Built-in 14" 1920x1200 panel
        "eDP-1,preferred,auto,1"

        # External monitors — auto-detect
        ",preferred,auto,1"
      ];

      exec-once = [
        "setup-monitors"
        "handle-monitor"
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
}
