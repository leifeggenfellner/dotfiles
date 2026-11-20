{ config, lib, ... }:
{
  perSystem = { pkgs, system, self', ... }: {
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

      rice-query =
        import ../rice/nix/_query-check.nix { inherit pkgs; };

      rice-boot =
        import ../rice/nix/_boot-check.nix { inherit pkgs; };

      # The ornaments plugin still compiles against the pinned Hyprland
      # (D-075); a Hyprland bump that changes its API fails here first.
      rice-ornaments-plugin = self'.packages.rice-ornaments;

      # The quickshell-runtime skill's API reference matches the pinned
      # Quickshell; after a nixpkgs bump, `nix run .#quickshell-api-ref`.
      quickshell-api-ref = pkgs.runCommand "quickshell-api-ref-check"
        { nativeBuildInputs = [ pkgs.python3 ]; }
        ''
          python3 ${../../scripts/quickshell-api-ref.py} ${pkgs.quickshell} ${pkgs.quickshell.version} generated
          diff -ru ${../../.claude/skills/quickshell-runtime/references/quickshell-api} generated \
            || { echo "Quickshell API reference is stale: nix run .#quickshell-api-ref"; exit 1; }
          touch $out
        '';

      rice-neovim =
        import ../rice/nix/_neovim-check.nix { inherit pkgs; };

      rice-tools =
        import ../rice/nix/_tools-check.nix { inherit pkgs; };

      rice-hyprfm =
        import ../rice/nix/_hyprfm-check.nix { inherit pkgs; };

      rice-prompt =
        import ../rice/nix/_prompt-check.nix {
          inherit pkgs;
          baseSettings = config.flake.nixosConfigurations.shitbox.config.home-manager.users.leif.programs.starship.settings;
        };

      monitor-control =
        import ../scripts/_monitor-control-check.nix { inherit pkgs; };

      nix-mcp = pkgs.callPackage ../programs/eca/nix-mcp/_check.nix {
        nix-mcp = pkgs.callPackage ../programs/eca/nix-mcp/_default.nix { };
      };

      eca-workflow-hooks = import ../programs/eca/_workflow-check.nix { inherit pkgs; };
      # Hyprland runs a Lua config (D-038); fail on IPC calls in the
      # source that still use the old dispatch/keyword syntax (#89).
      hyprland-lua-syntax = pkgs.runCommand "hyprland-lua-syntax-check"
        { nativeBuildInputs = [ pkgs.python3 ]; }
        ''
          python3 ${./_hyprland-lua-syntax.py} ${../.}
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
