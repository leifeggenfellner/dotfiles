{ inputs, ... }: {
  flake.nixosModules.services-scramgit =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        inputs.scramgit.defaultPackage.${pkgs.stdenv.hostPlatform.system}
      ];
    };
}
