{ inputs, ... }:
{
  perSystem = { system, ... }:
    let
      pre-commit-lib = inputs.pre-commit-hooks-nix.lib.${system};
    in
    {
      checks = {
        pre-commit-check = pre-commit-lib.run {
          src = ./../..;
          hooks = {
            statix.enable = true;
            deadnix.enable = true;
            nil.enable = true;
            nixpkgs-fmt.enable = true;
            shellcheck.enable = true;
            beautysh.enable = true;
          };
        };
      };
    };
}
