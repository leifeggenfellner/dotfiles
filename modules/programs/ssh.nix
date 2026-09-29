_: {
  flake.homeModules.programs-ssh =
    { osConfig, lib, ... }:
    let
      # With secrets enabled the personal key is sops-managed and decrypted
      # into /run/secrets; otherwise fall back to the conventional location.
      identityFile =
        if osConfig.secrets.enable then
          osConfig.sops.secrets."ssh/id_ed25519".path
        else
          "~/.ssh/id_ed25519";
    in
    {
      programs.ssh = {
        enable = true;

        enableDefaultConfig = false;
        settings."*" = {
          forwardAgent = false;
          addKeysToAgent = "yes";
          compression = true;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        } // lib.optionalAttrs osConfig.secrets.enable {
          inherit identityFile;
        };

        settings = {
          "github.com" = {
            hostname = "ssh.github.com";
            port = 443;
            user = "git";
            identitiesOnly = true;
            inherit identityFile;
          };

          "10.0.0.*" = {
            forwardAgent = true;
          };
        };
      };
    };
}
