_: {
  flake.nixosModules.programs-cachix =
    { pkgs, lib, ... }:
    {
      environment.systemPackages = [ pkgs.cachix ];

      nix.settings = {
        substituters = lib.mkAfter [
          "https://cache.nixos.org/"
          "https://hyprland.cachix.org"
          "https://cache.iog.io"
          "https://leifeggenfellner.cachix.org"
          "https://nix-community.cachix.org"
        ];
        trusted-substituters = [ "https://hyprland.cachix.org" ];
        trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
          "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
          "leifeggenfellner.cachix.org-1:+eB88ym7mLK0BmusC9IXqGNOj4niilnp3EI1T7Yi6fY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };
}
