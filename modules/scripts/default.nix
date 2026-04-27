_: {
  flake.homeModules.scripts =
    { pkgs, config, ... }:
    let
      countdown-timer = pkgs.callPackage ./_countdown-timer.nix { inherit pkgs; };
      gen-ssh-key = pkgs.callPackage ./_gen-ssh-key.nix { inherit pkgs; };
      set-monitor = pkgs.callPackage ./_set-monitor.nix { inherit pkgs; };
      setup-monitors = pkgs.callPackage ./_setup-monitors.nix { inherit pkgs; };
      handle-monitor = pkgs.callPackage ./_handle-monitor.nix { inherit pkgs; };
      lock-screen = pkgs.callPackage ./_lock-screen.nix { inherit pkgs; };
      gum-scripts = pkgs.callPackage ./_gum-scripts.nix {
        inherit pkgs;
        inherit (config) colorScheme;
      };
    in
    {
      home.packages =
        [
          countdown-timer
          gen-ssh-key
          set-monitor
          setup-monitors
          handle-monitor
          lock-screen

          gum-scripts.system-cleanup
          gum-scripts.project-launcher
          gum-scripts.gswitch
          gum-scripts.cm
          gum-scripts.gadd
          gum-scripts.glog
        ]
        ++ (pkgs.sxm.scripts or [ ]);
    };
}
