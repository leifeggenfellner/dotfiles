_: {
  flake.homeModules.programs-ssh = {
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
      };

      settings = {
        "github.com" = {
          hostname = "ssh.github.com";
          port = 443;
          user = "git";
          identitiesOnly = true;
          identityFile = "~/.ssh/id_ed25519";
        };

        "10.0.0.*" = {
          forwardAgent = true;
        };
      };
    };
  };
}
