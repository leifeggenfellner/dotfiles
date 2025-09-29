{ config, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.hostName = "shitbox";
  users.users = {
    leif = {
      isNormalUser = true;
      initialHashedPassword = "$7$CU..../....7emauu/nSIai9Z3k.5nme1$6FDaMoeVeQBls.bZ3FsswOVWoeB.ILPtcIAqZh24f54";
      openssh.authorizedKeys.keys = [
      ];
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "plugdev"
      ];
    };
  };

  programs.hyprland.settings = lib.mkIf (config.environment.desktop.windowManager == "hyprland") {
    monitor = [
      # laptop screen
      "eDP-1,1920x1200,2560x1440,1"

      # external monitors
      "desc:HP Inc. HP E45c G5 CNC50212K0,2560x1440,0x0,1"
      "desc:HP Inc. HP E45c G5 CNC1000000,2560x1440,2560x0,1"

      # fallback
      ",highrr,auto,1"
    ];

    workspace = [
      # left external = CNC50212K0, right external = CNC1000000
      "1, monitor:desc:HP Inc. HP E45c G5 CNC50212K0"
      "2, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "3, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "4, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "5, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "6, monitor:desc:HP Inc. HP E45c G5 CNC50212K0"
      "7, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "8, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
      "9, monitor:desc:HP Inc. HP E45c G5 CNC1000000"
    ];
  };
  # Modules loaded
  system = {
    disks.extraStoreDisk.enable = false;
    bluetooth.enable = true;
  };

  service = {
    blueman.enable = true;
    touchpad.enable = true;
  };
}
