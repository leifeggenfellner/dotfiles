_: {
  flake.nixosModules.programs-base =
    { pkgs, ... }:
    {
      environment = {
        systemPackages = with pkgs; [
          wget
          git
        ];

        variables.EDITOR = "nvim";
      };

      programs = {
        fuse.userAllowOther = true;
        nano.enable = false;
        nh = {
          enable = true;
          clean.enable = true;
          clean.extraArgs = "--keep-since 4d --keep 3";
          flake = "/home/leif/Sources/dotfiles";
        };
      };
    };
}
