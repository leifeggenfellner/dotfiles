{ config, lib, ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Mechanical contract enforcement for the rice runtime (D-015).
    # Fails the flake check on layer-import violations or theme literals.
    checks = {
      rice-lint = pkgs.runCommand "rice-lint"
        {
          runtime = ../rice/runtime/quickshell;
        } ''
        bash ${../../scripts/rice-lint.sh} "$runtime"
        touch $out
      '';

      rice-manifest-validation =
        import ../rice/nix/_manifest-validation-check.nix { inherit pkgs; };

      rice-theme-switch =
        import ../rice/nix/_theme-switch-check.nix { inherit pkgs; };

      monitor-control =
        import ../scripts/_monitor-control-check.nix { inherit pkgs; };

      copilot-agent-contract = pkgs.runCommand "copilot-agent-contract"
        {
          nativeBuildInputs = [ pkgs.python3Packages.pyyaml ];
        } ''
        python ${../../scripts/copilot-agent-lint.py} \
          --workspace-dir ${../../.github/agents} \
          --shared-dir ${../programs/vscode/prompts} \
          --install-file ${../programs/vscode.nix}
        touch $out
      '';
    } // lib.optionalAttrs (system == "x86_64-linux") {
      hyprland-generated-config =
        let
          generatedConfig = config.flake.nixosConfigurations.shitbox.config.home-manager.users.leif.home.file."/home/leif/.config/hypr/hyprland.lua".source;
        in
        pkgs.runCommand "hyprland-generated-config-check"
          {
            nativeBuildInputs = [ pkgs.lua ];
          }
          ''
            luac -p ${generatedConfig}
            grep -F 'hl.exec_cmd("uwsm finalize && systemctl --user start --no-block monitor-control.service")' ${generatedConfig}
            grep -F 'hl.on("hyprland.start"' ${generatedConfig}
            ! grep -E 'setup-monitors|thunderbolt-wait|handle-monitor|set-monitor|hl\.monitor\(' ${generatedConfig}
            ! grep -F '["monitor"]' ${generatedConfig}
            touch $out
          '';
    };
  };
}
