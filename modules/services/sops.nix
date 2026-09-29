_: {
  flake.nixosModules.services-sops =
    { config, lib, ... }:
    let
      cfg = config.secrets;

      userSecret = sopsFile: key: {
        inherit sopsFile key;
        owner = "leif";
        mode = "0400";
      };
    in
    {
      options.secrets.enable = lib.mkEnableOption ''
        the sops-encrypted secrets under `sops/`, decrypted into /run/secrets
        at activation. Only enable on hosts enrolled in `.sops.yaml` (see
        `sops-enroll-host` in the dev shell)
      '';

      config = lib.mkIf cfg.enable {
        # Decrypt with the host's SSH key, read straight from /persist so it
        # doesn't depend on the impermanence bind mount of /etc/ssh existing
        # yet when secrets are set up during activation.
        sops = {
          age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
          gnupg.sshKeyPaths = [ ];

          secrets = {
            "ssh/id_ed25519" = userSecret ../../sops/ssh.yaml "id_ed25519";
            "github/token" = userSecret ../../sops/github.yaml "token";
          };
        };
      };
    };
}
