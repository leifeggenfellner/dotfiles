_: {
  flake.homeModules.services-keyring-unlock =
    { lib, osConfig, pkgs, ... }:
    let
      passwordPath = osConfig.sops.secrets."keyring/password".path;
    in
    {
      # greetd autologs in, so PAM never sees a password and the login keyring
      # stays locked; apps like Slack then prompt for it on launch. Unlock it
      # from the sops-managed password before the graphical session starts.
      config = lib.mkIf (osConfig.environment.desktop.enable && osConfig.secrets.enable) {
        systemd.user.services.keyring-unlock = {
          Unit = {
            Description = "Unlock the GNOME login keyring from sops";
            Before = [ "graphical-session.target" ];
            After = [ "graphical-session-pre.target" ];
          };
          Service = {
            Type = "oneshot";
            ExecStart = "${pkgs.python3}/bin/python3 ${../scripts/_keyring-unlock.py}";
            StandardInput = "file:${passwordPath}";
          };
          Install.WantedBy = [ "graphical-session-pre.target" ];
        };
      };
    };
}
