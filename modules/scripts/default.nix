let
  scripts = { pkgs, ... }:
    let
      countdown-timer = pkgs.callPackage ./countdown-timer.nix { inherit pkgs; };
      gen-ssh-key = pkgs.callPackage ./gen-ssh-key.nix { inherit pkgs; };
      set-monitor = pkgs.callPackage ./set-monitor.nix { inherit pkgs; };
      handle-monitor = pkgs.callPackage ./handle-monitor.nix { inherit pkgs; };
      gum-scripts = pkgs.callPackage ./gum-scripts.nix { inherit pkgs; };
    in
    {
      home.packages =
        [
          countdown-timer # countdown timer with figlet
          gen-ssh-key # generate ssh key and add it to the system
          set-monitor # set monitor resolution
          handle-monitor # handle monitor resolution

          # Gum scripts
          gum-scripts.system-cleanup # system cleanup with gum
          gum-scripts.project-launcher # project launcher with gum
          gum-scripts.git-switch # git branch switcher with gum
          gum-scripts.git-commit-helper # git commit helper with gum
        ]
        ++ (pkgs.sxm.scripts or [ ]);
    };
in
[ scripts ]
