_: {
  perSystem = { pkgs, ... }: {
    # Mechanical contract enforcement for the rice runtime (D-015).
    # Fails the flake check on layer-import violations or theme literals.
    checks.rice-lint = pkgs.runCommand "rice-lint"
      {
        runtime = ../rice/runtime/quickshell;
      } ''
      bash ${../../scripts/rice-lint.sh} "$runtime"
      touch $out
    '';
  };
}
