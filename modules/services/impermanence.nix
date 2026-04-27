_: {
  flake.nixosModules.services-impermanence =
    { config, lib, ... }:
    let
      developSpecificDirs = [
        ".cache/bleep"
        ".cache/bloop"
        ".cache/coursier"
        ".cargo"
        ".m2"
        ".npm"
        ".pulumi"
      ];
    in
    {
      environment.persistence."/persist" = {
        hideMounts = true;
        directories = [
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/var/log"

          "/usr/systemd-placeholder"
        ];
        users.leif = {
          directories = [
            "Documents"
            "Downloads"
            "Music"
            "Pictures"
            "Projects"
            "Sources"
            {
              directory = ".gnupg";
              mode = "0700";
            }
            {
              directory = ".ssh";
              mode = "0700";
            }
            {
              directory = ".local/share/direnv";
              mode = "0700";
            }
            {
              directory = ".local/share/keyrings";
              mode = "0700";
            }
            ".config/waypaper"
            ".local/share/swww"
          ]
          ++ (lib.optionals config.environment.desktop.develop developSpecificDirs);
        };
      };
    };
}
