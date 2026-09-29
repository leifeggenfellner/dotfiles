_: {
  flake.homeModules.programs-eca =
    { osConfig, config, lib, pkgs, ... }:
    let
      inherit (osConfig.environment) desktop;
      cfg = config.program.eca;

      ecaVersion = "0.157.0";

      # Only the amd64 release asset is statically linked; the aarch64 one
      # needs patchelf'ing against glibc/zlib.
      ecaAssets = {
        x86_64-linux = {
          file = "eca-native-static-linux-amd64.zip";
          hash = "sha256-wAjn+g9d3vaIQ6QX7wZ5bCVl668e5nOSVB+i8LXuQFs=";
        };
        aarch64-linux = {
          file = "eca-native-linux-aarch64.zip";
          hash = "sha256-bkOYBP8PQg+guUoi86ZaaQXQXDZ3FvLydVo901+Huas=";
        };
      };
      ecaAsset = ecaAssets.${pkgs.stdenv.hostPlatform.system};

      eca-server = pkgs.stdenv.mkDerivation {
        pname = "eca";
        version = ecaVersion;

        src = pkgs.fetchurl {
          url = "https://github.com/editor-code-assistant/eca/releases/download/${ecaVersion}/${ecaAsset.file}";
          inherit (ecaAsset) hash;
        };

        nativeBuildInputs = [
          pkgs.unzip
          pkgs.autoPatchelfHook
        ];
        buildInputs = [ pkgs.zlib ];

        dontStrip = true;

        unpackPhase = ''
          runHook preUnpack
          unzip $src
          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall
          install -Dm755 eca $out/bin/eca
          runHook postInstall
        '';

        meta = with lib; {
          description = "Editor Code Assistant server (pinned ${ecaVersion})";
          homepage = "https://github.com/editor-code-assistant/eca";
          license = licenses.asl20;
          platforms = builtins.attrNames ecaAssets;
          mainProgram = "eca";
        };
      };

      ecaHooks = import ./eca/_hooks.nix { inherit pkgs; };

      nixMcpManaged = cfg.nixMcp.enable;
      rootsJson =
        if nixMcpManaged then
          pkgs.writeText "nix-mcp-roots.json" (builtins.toJSON { roots = cfg.nixMcp.roots; })
        else null;
      nixMcpSettings = lib.optionalAttrs nixMcpManaged {
        mcpServers.nix = {
          command = lib.getExe cfg.nixMcp.package;
          args = [ "--config" rootsJson ];
          env = { };
          disabled = false;
        };
        toolCall.approval.allow = {
          nix__flake_metadata = { };
          nix__flake_show = { };
          nix__flake_check = { };
          nix__eval = { };
          nix__build = { };
          nix__develop = { };
          nix__run = { };
          nix__sbt = { };
        };
      };

      # Static defaults ported from the former emacs-flake `programs.merrinx-emacs.eca`
      # module. `defaultAgent` decides which primary agent new chats start with;
      # the custom subagents under `eca/agents/` are restricted via `spawnableBy`
      # and are only discoverable from that agent. The hooks record lead workflow
      # progress and keep incomplete implementation turns running through
      # verification and review.
      defaultEcaSettings = {
        defaultAgent = "lead";
        toolCall.approval = {
          byDefault = "ask";
          allow = {
            eca__shell_command.argsMatchers.command = [
              "^nix flake check[^;&|<>`$()]*$"
              "^nix build( [^-][^;&|<>`$()]*)?$"
              "^nix eval( [^-][^;&|<>`$()]*)?$"
              "^nix develop(?!.*\\s(-c|--command)\\s)[^;&|<>`$()]*$"
              "^nix develop[^;&|<>`$()]*\\s(-c|--command)\\s(sbt|sbtn|scalafmt|scalafix|cargo|pytest|ruff|black|npm|pnpm|yarn|mvn|\\./mvnw|make)[^;&|<>`$()]*$"
              "^nix fmt[^;&|<>`$()]*$"
              "^(sbt|sbtn) (compile|test|testQuick|scalafmtCheckAll|scalafixAll( --check)?)[^;&|<>`$()]*$"
              "^(sbt|sbtn) [a-zA-Z0-9._-]+/(compile|test|testQuick|scalafmtCheckAll|scalafixAll( --check)?)[^;&|<>`$()]*$"
              "^scalafmt --check[^;&|<>`$()]*$"
              "^scalafix --check[^;&|<>`$()]*$"
              "^cargo (test|clippy|check|build|fmt)[^;&|<>`$()]*$"
              "^mvn (verify|test|compile)[^;&|<>`$()]*$"
              "^./mvnw (verify|test|compile)[^;&|<>`$()]*$"
              "^pytest[^;&|<>`$()]*$"
              "^ruff (check|format --check)[^;&|<>`$()]*$"
              "^black --check[^;&|<>`$()]*$"
              "^npm run (test|typecheck|lint|build|check)[^;&|<>`$()]*$"
              "^pnpm (test|typecheck|lint|build|check)[^;&|<>`$()]*$"
              "^yarn (test|typecheck|lint|build|check)[^;&|<>`$()]*$"
              "^npx (tsc|vue-tsc|eslint|vitest)[^;&|<>`$()]*$"
              "^git (status|diff|log|show|rev-parse)[^;&|<>`$()]*$"
            ];
            eca__git.argsMatchers.command = [
              "^git (status|diff|log|show|rev-parse)[^;&|<>`$()]*$"
              "^gh (pr|issue|run) (view|diff|list)[^;&|<>`$()]*$"
            ];
          };
          deny = {
            eca__shell_command.argsMatchers.command = [
              ".*\\bnix\\b.*--expr\\b.*"
            ];
            eca__git.argsMatchers.command = [ ];
          };
        };
        hooks = {
          version-git-approval = {
            type = "preToolCall";
            matcher = "eca__git|eca__shell_command";
            visible = false;
            description = "Auto-approve version-agent Git commands";
            actions = [{ type = "shell"; file = "${ecaHooks.gitApproval}/bin/eca-version-git-approval"; }];
          };
          lead-workflow-record = {
            type = "postToolCall";
            matcher = "eca__spawn_agent";
            visible = false;
            description = "Track which subagents ran in a lead chat";
            actions = [{ type = "shell"; file = "${ecaHooks.record}/bin/eca-lead-workflow-record"; }];
          };
          lead-workflow-verify = {
            type = "postRequest";
            visible = false;
            description = "Force a verification turn after implementation subagents ran";
            actions = [{ type = "shell"; file = "${ecaHooks.verify}/bin/eca-lead-workflow-verify"; }];
          };
        };
      };

      effectiveEcaSettings =
        lib.recursiveUpdate (lib.recursiveUpdate defaultEcaSettings nixMcpSettings) cfg.extraSettings;
    in
    {
      options.program.eca = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Whether to install ECA (Editor Code Assistant): the pinned server
            binary plus the shared `AGENTS.md`/agents/rules/commands/skills
            bundle under `~/.config/eca/`. Config is identical for every ECA
            client (VS Code extension, `eca` CLI, etc.) that reads it.
          '';
        };

        server = lib.mkOption {
          type = lib.types.package;
          default = eca-server;
          defaultText = lib.literalExpression "pinned eca release";
          description = ''
            The ECA server package. Exposed so editor integrations (e.g. the
            VS Code extension's `eca.serverPath` setting) can pin to this
            reproducible build instead of letting the client manage its own
            download.
          '';
        };

        extraSettings = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Additional ECA settings recursively overlaid on the managed settings.";
        };

        nixMcp = {
          enable = lib.mkEnableOption "the Nix MCP server";
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.callPackage ./eca/nix-mcp/_default.nix { };
            defaultText = lib.literalExpression "pkgs.callPackage ./eca/nix-mcp/_default.nix { }";
            description = "The Nix MCP server package.";
          };
          roots = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Absolute canonical flake roots exposed to the Nix MCP server.";
          };
        };
      };

      config = lib.mkIf (cfg.enable && desktop.enable && desktop.develop) {
        assertions = lib.optional cfg.nixMcp.enable {
          assertion =
            cfg.nixMcp.roots != [ ]
            && lib.all (root: lib.hasPrefix "/" root) cfg.nixMcp.roots
            && lib.length (lib.unique cfg.nixMcp.roots) == lib.length cfg.nixMcp.roots;
          message = "program.eca.nixMcp.roots must be nonempty, unique, and absolute when Nix MCP is enabled.";
        };

        home.packages = [ cfg.server ];

        home.persistence."/persist/" = {
          directories = [ ".cache/eca" ];
        };

        xdg.configFile = {
          "eca/AGENTS.md".source = ./eca/AGENTS.md;
          "eca/config.json".text = builtins.toJSON effectiveEcaSettings;
          "eca/agents" = {
            source = ./eca/agents;
            recursive = true;
          };
          "eca/rules" = {
            source = ./eca/rules;
            recursive = true;
          };
          "eca/commands" = {
            source = ./eca/commands;
            recursive = true;
          };
          "eca/skills" = {
            source = ./eca/skills;
            recursive = true;
          };
        };
      };
    };
}
