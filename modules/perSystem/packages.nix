_: {
  perSystem = { pkgs, ... }: {
    packages = {
      repl = pkgs.callPackage ./../../pkgs/repl { };

      # Regenerates the quickshell-runtime skill's API reference from the
      # pinned Quickshell; the `quickshell-api-ref` check fails until it runs.
      quickshell-api-ref = pkgs.writeShellApplication {
        name = "quickshell-api-ref";
        runtimeInputs = [ pkgs.python3 pkgs.git ];
        text = ''
          root="$(git rev-parse --show-toplevel)"
          python3 ${./../../scripts/quickshell-api-ref.py} ${pkgs.quickshell} ${pkgs.quickshell.version} \
            "$root/.claude/skills/quickshell-runtime/references/quickshell-api"
        '';
      };
    };
  };
}
