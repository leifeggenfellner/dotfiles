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

    checks.rice-manifest-validation =
      import ../rice/nix/_manifest-validation-check.nix { inherit pkgs; };

    checks.rice-theme-switch =
      import ../rice/nix/_theme-switch-check.nix { inherit pkgs; };

    checks.copilot-agent-contract = pkgs.runCommand "copilot-agent-contract"
      {
        nativeBuildInputs = [ pkgs.python3Packages.pyyaml ];
      } ''
      python ${../../scripts/copilot-agent-lint.py} \
        --workspace-dir ${../../.github/agents} \
        --shared-dir ${../programs/vscode/prompts} \
        --install-file ${../programs/vscode.nix}
      touch $out
    '';
  };
}
