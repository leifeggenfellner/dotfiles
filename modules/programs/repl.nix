{ config, ... }: {
  flake.homeModules.programs-repl =
    { pkgs, ... }:
    {
      home.packages = [
        config.flake.packages.${pkgs.stdenv.hostPlatform.system}.repl
      ];
    };
}
