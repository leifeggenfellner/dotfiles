{ config, lib, ... }:

let
  # monitor IDs — single place to edit long desc strings
  monitorLeft  = "desc:HP Inc. HP E45c G5 CNC50212K0";
  monitorRight = "desc:HP Inc. HP E45c G5 CNC1000000";
  laptop       = "eDP-1";

  # workspace definitions (id, short name, assigned monitor)
  workspaceDefs = [
    { id = "1"; name = "code"; monitor = monitorLeft;  }  # VS Code
    { id = "2"; name = "alacritty"; monitor = monitorLeft; }  # terminals (Alacritty)
    { id = "3"; name = "zen"; monitor = monitorRight; }  # Zen Browser
    { id = "4"; name = "comms"; monitor = monitorRight; }  # Slack / Discord
    { id = "5"; name = "media"; monitor = monitorRight; }  # other / media
    { id = "6"; name = "vm"; monitor = monitorLeft; }  # VMs / heavy tasks
    { id = "7"; name = "sys"; monitor = monitorLeft; }  # system tools
    { id = "8"; name = "chat"; monitor = monitorRight; }  # ephemeral chat / quick tasks
    { id = "9"; name = "misc"; monitor = monitorRight; }  # scratch / floating
  ];

  # build hyprland workspace strings like "1, monitor:desc:..."
  # Note: Hyprland uses workspace ID only, not "id:name" format
  hyprWorkspaces = builtins.map (ws:
    "${ws.id}, monitor:${ws.monitor}"
  ) workspaceDefs;
in
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
        # Add your SSH keys here if needed
      ];
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "plugdev"
      ];
    };
  };

  # Enable desktop environment with Hyprland
  environment.desktop = {
    enable = true;
    windowManager = "hyprland";
  };

  # Hyprland configuration
  programs.hyprland = {
    enable = true;
    settings = {
      monitor = [
        # laptop screen (fallback)
        "${laptop},1920x1200,2560x1440,1"

        # external monitors (explicit)
        "${monitorLeft},2560x1440,0x0,1"
        "${monitorRight},2560x1440,2560x0,1"

        # fallback
        ",highrr,auto,1"
      ];

      # Generated workspaces (workspace ID, monitor assignment)
      workspace = hyprWorkspaces;

      # window rules v2 — use the exact classes observed with `hyprctl clients`
      windowrulev2 = [
        # VS Code (class: Code)
        "workspace 1,class:(Code)"

        # Alacritty (class: Alacritty)
        "workspace 2,class:(Alacritty)"

        # Zen Browser (class: zen)
        "workspace 3,class:(zen)"

        # Slack (class: Slack)
        "workspace 4,class:(Slack)"

        # Discord (class: discord)
        "workspace 4,class:(discord)"

        # Optional: make some windows float
        "float,class:(pavucontrol)"
      ];
    };
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
