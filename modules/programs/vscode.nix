{ osConfig
, config
, lib
, pkgs
, ...
}:
let
  inherit (osConfig.environment) desktop;
  cfg = config.program.vscode;

  sharedAliases = import ../../system/programs/fish/fish-aliases.nix { inherit pkgs lib; };

  # VS Code only tools
  vscodeOnlyTools = with pkgs; [
    # Language servers and formatters
    nil
    metals
    nixpkgs-fmt
    nodePackages.prettier
    google-java-format
    black
    rustfmt
    kotlin-language-server

    # JavaScript/TypeScript ecosystem
    nodejs_20
    nodePackages.typescript
    typescript-language-server
    vue-language-server

    # Fonts for proper icon rendering
    nerd-fonts.roboto-mono

    # Utilities
    jq

    # Tools needed for aliases
    bat
    eza
    ncdu
    prettyping
    mimeo
    docker-compose

    # Git and SSH tools
    git
    openssh
    git-credential-manager
  ];

  # Create a PATH string for these tools
  vscodeOnlyPath = "${pkgs.lib.makeBinPath vscodeOnlyTools}";

  # Add wrappers bin for sudo and other setuid programs
  wrappersPath = "/run/wrappers/bin";

  # Create a PATH string for system tools
  systemToolsPath = "/run/current-system/sw/bin";

  # Use the nix-profile path for Home Manager packages
  homeManagerPath = "/etc/profiles/per-user/${config.home.username}/bin";
in
{
  options.program.vscode = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable VSCode";
    };

    godMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable vim mode";
    };

    theme = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
        "catppuccin"
      ];
      default = "catppuccin";
      description = "VSCode color theme";
    };
  };

  config = lib.mkIf (cfg.enable && desktop.enable && desktop.develop) {

    programs.vscode = {
      enable = true;
      package = pkgs.vscode;
      mutableExtensionsDir = true;
      profiles.default = {
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        extensions =
          with pkgs.vscode-extensions;
          [
            # Copilot
            github.copilot
            github.copilot-chat

            # Editor
            editorconfig.editorconfig
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode-remote.remote-containers
            ms-vscode.makefile-tools
            mkhl.direnv
            bmalehorn.vscode-fish

            # Formatters
            esbenp.prettier-vscode

            # Haskell
            haskell.haskell
            justusadam.language-haskell

            # Java
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-dependency
            vscjava.vscode-java-pack

            # Javascript/CSS/TypeScript
            vue.volar
            bradlc.vscode-tailwindcss
            dbaeumer.vscode-eslint
            usernamehw.errorlens
            christian-kohler.path-intellisense
            christian-kohler.npm-intellisense
            formulahendry.auto-rename-tag
            formulahendry.auto-close-tag

            # Kotlin
            mathiasfrohlich.kotlin

            # Nix
            bbenoist.nix
            jnoortheen.nix-ide

            # Python
            ms-python.python
            ms-pyright.pyright
            ms-python.black-formatter

            # Rust
            rust-lang.rust-analyzer
            tamasfe.even-better-toml

            # Scala/Metals
            scalameta.metals
            scala-lang.scala

            # Docker
            ms-azuretools.vscode-docker

            # Yaml/Markdown
            bierner.github-markdown-preview
            bierner.markdown-checkbox
            bierner.markdown-emoji
            bierner.markdown-footnotes
            bierner.markdown-mermaid
            bierner.markdown-preview-github-styles
          ]
          ++ lib.optionals cfg.godMode [ vscodevim.vim ]
          ++ [
            # Theme extensions
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "catppuccin-vsc";
              publisher = "Catppuccin";
              version = "3.18.0";
              sha256 = "sha256-57c0HRdEABLz03qozeQgFJH1NaWUbA+7tDJv0V4At8M=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "catppuccin-vsc-icons";
              publisher = "Catppuccin";
              version = "1.24.0";
              sha256 = "sha256-2M7N4Ccw9FAaMmG36hGHi6i0i1qR+uPCSgXELAA03Xk=";
            })

            # Testing tools - Quokka
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "quokka-vscode";
              publisher = "WallabyJs";
              version = "1.0.742";
              sha256 = "sha256-wNyKxMbop4P9snHt2z/4ATdUNgAwvgqU3LppoXYqIKQ=";
            })

            # Vue/TypeScript/Web Development extensions
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "headwind";
              publisher = "heybourn";
              version = "1.7.0";
              sha256 = "sha256-yXsZoSuJQTdbHLjEERXX2zVheqNYmcPXs97/uQYa7og=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "pretty-ts-errors";
              publisher = "yoavbls";
              version = "0.6.1";
              sha256 = "sha256-LvX21nEjgayNd9q+uXkahmdYwzfWBZOhQaF+clFUUF4=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "typescript-hero";
              publisher = "rbbit";
              version = "3.0.0";
              sha256 = "sha256-I5Hbwe3E4HDGl2oMgkHYBvhtFA49UERP9WRStQ4hwMk=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "console-ninja";
              publisher = "WallabyJs";
              version = "1.0.478";
              sha256 = "sha256-WbSzN7aZxyjWFlpeSiJJMY+5gyxtpYUDn4qe1q6XIjk=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "vscode-css-peek";
              publisher = "pranaygp";
              version = "4.4.3";
              sha256 = "sha256-oY+mpDv2OTy5hFEk2DMNHi9epFm4Ay4qi0drCXPuYhU=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "color-highlight";
              publisher = "naumovs";
              version = "2.8.0";
              sha256 = "sha256-mT2P1lEdW66YkDRN6fi0rmmvvyBfXiJjAUHns8a8ipE=";
            })
            (pkgs.vscode-utils.extensionFromVscodeMarketplace {
              name = "dotenv";
              publisher = "mikestead";
              version = "1.0.1";
              sha256 = "sha256-dieCzNOIcZiTGu4Mv5zYlG7jLhaEsJR05qbzzzQ7RWc=";
            })
          ];

        userSettings = {
          # Theme settings
          "workbench.colorTheme" =
            if cfg.theme == "catppuccin" then
              "Catppuccin Mocha"
            else if cfg.theme == "dark" then
              "Default Dark Modern"
            else
              "Default Light Modern";
          "workbench.preferredDarkColorTheme" = "Default Dark Modern";
          "workbench.preferredLightColorTheme" = "Default Light Modern";
          "window.autoDetectColorScheme" = false;

          # Icon theme
          "workbench.iconTheme" = "catppuccin-mocha";

          # Sidebar placement
          "workbench.sideBar.location" = "right";

          # Performance improvements for Scala/Metals
          "files.watcherExclude" = {
            "**/.bloop" = true;
            "**/.metals" = true;
            "**/.ammonite" = true;
            "**/node_modules" = true;
            "**/.git" = true;
          };

          # Git improvements
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.path" = "${pkgs.git}/bin/git";
          "git.decorations.enabled" = true;
          "git.showPushSuccessNotification" = true;

          # GitHub Copilot settings
          "github.copilot.nextEditSuggestions.enabled" = true;

          # Editor improvements
          "workbench.tree.indent" = 20;
          "workbench.startupEditor" = "none";
          "editor.formatOnSave" = true;
          "editor.formatOnPaste" = true;
          "editor.minimap.enabled" = false;
          "editor.defaultFormatter" = "esbenp.prettier-vscode";
          "editor.lineNumbers" = "relative";
          "editor.linkedEditing" = true;
          "editor.bracketPairColorization.enabled" = true;
          "editor.guides.bracketPairs" = "active";
          "editor.inlineSuggest.enabled" = true;
          "editor.suggestSelection" = "first";
          "editor.quickSuggestions" = {
            "other" = true;
            "comments" = false;
            "strings" = false;
          };

          # Search improvements
          "search.exclude" = {
            "**/node_modules" = true;
            "**/bower_components" = true;
            "**/dist" = true;
            "**/coverage" = true;
            "**/.git" = true;
            "**/.svn" = true;
            "**/.hg" = true;
            "**/CVS" = true;
            "**/.DS_Store" = true;
            "**/Thumbs.db" = true;
            "**/.metals" = true;
            "**/.bloop" = true;
          };

          # Explorer improvements
          "explorer.fileNesting.enabled" = true;
          "explorer.fileNesting.patterns" = {
            "*.ts" = "\${capture}.js, \${capture}.d.ts, \${capture}.js.map";
            "*.tsx" = "\${capture}.jsx";
            "package.json" = "package-lock.json, yarn.lock, pnpm-lock.yaml, bun.lockb";
            "tsconfig.json" = "tsconfig.*.json";
            ".env" = ".env.*";
          };

          # Editor font configuration for nerd icons
          "editor.fontFamily" = "RobotoMono Nerd Font, 'RobotoMono Nerd Font Mono', 'Courier New', monospace";
          "editor.fontSize" = 14;
          "editor.fontLigatures" = true;
          "editor.renderWhitespace" = "selection";
          "editor.renderControlCharacters" = true;

          # Terminal font configuration for nerd icons
          "terminal.integrated.fontFamily" = "RobotoMono Nerd Font, 'RobotoMono Nerd Font Mono', monospace";
          "terminal.integrated.fontSize" = 14;

          # Terminal environment configuration
          "terminal.integrated.env.linux" = {
            "TERM_PROGRAM" = "vscode";
            # Preserve SSH agent socket
            "SSH_AUTH_SOCK" = "\${SSH_AUTH_SOCK}";
            # Preserve git configuration
            "GIT_ASKPASS" = "\${GIT_ASKPASS}";
            "GIT_SSH" = "${pkgs.openssh}/bin/ssh";
          };

          # Use external terminal for better compatibility
          "terminal.integrated.defaultProfile.linux" = "fish";
          "terminal.integrated.profiles.linux" = {
            "fish" = {
              "path" = "${pkgs.fish}/bin/fish";
              "args" = [ "--login" ];
            };
          };

          "terminal.integrated.inheritEnv" = true;
          "terminal.integrated.shellIntegration.enabled" = true;

          # Code lens for better navigation
          "java.referencesCodeLens.enabled" = true;
          "java.implementationsCodeLens.enabled" = true;
          "typescript.implementationsCodeLens.enabled" = true;
          "typescript.referencesCodeLens.enabled" = true;
          "typescript.referencesCodeLens.showOnAllFunctions" = true;

          # File type associations
          "files.associations" = {
            "*.kt" = "gradle-kotlin-dsl";
            "*.css" = "tailwindcss";
            "*.vue" = "vue";
          };

          # Auto-import improvements
          "javascript.updateImportsOnFileMove.enabled" = "always";
          "typescript.updateImportsOnFileMove.enabled" = "always";

          # TypeScript/Javascript specific settings
          "typescript.preferences.importModuleSpecifier" = "shortest";
          "javascript.preferences.importModuleSpecifier" = "shortest";
          "typescript.suggest.autoImports" = true;
          "javascript.suggest.autoImports" = true;

          # Console Ninja
          "console-ninja.featureSet" = "Community";

          # ESLint configuration
          "eslint.validate" = [
            "javascript"
            "javascriptreact"
            "typescript"
            "typescriptreact"
            "vue"
          ];
          "eslint.probe" = [
            "javascript"
            "javascriptreact"
            "typescript"
            "typescriptreact"
            "vue"
          ];

          # UX improvements
          "explorer.confirmDelete" = false;
          "explorer.confirmDragAndDrop" = false;
          "diffEditor.ignoreTrimWhitespace" = false;
          "security.workspace.trust.untrustedFiles" = "open";

          # Error Lens configuration
          "errorLens.enabledDiagnosticLevels" = [
            "error"
            "warning"
            "info"
          ];
          "errorLens.excludeBySource" = [ "eslint(prettier/prettier)" ];

          # Metals configuration - let it use environment JAVA_HOME
          "metals.sbtScript" = "${pkgs.sbt}/bin/sbt";
          "metals.javaHome" = null;
          "metals.customRepositories" = [ ];
          "metals.bloopSbtLocation" = "${pkgs.bloop}/bin/bloop";
          "metals.scalafixConfigPath" = ".scalafix.conf";
          "metals.scalafixOnCompile" = false;
          "metals.scalafixConfig" = ''
            rules = [
              OrganizeImports
            ]

            OrganizeImports {
              targetDialect = Scala3
              removeUnused = true
              groupedImports = Merge
              groups = [
                "re:javax?\\."
                "scala."
                "re:^(?!scala\\.).*"
              ]
            }
          '';
          "metals.serverProperties" = [
            "-Dmetals.client=vscode"
            "-Xmx2G"
            "-Xms2G"
            "-XX:MaxMetaspaceSize=512m"
            "-Dscalafix.timeout=30s"
          ];

          # Nix Language Server
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${pkgs.nil}/bin/nil";
          "nil.formatting.command" = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
          "nix.serverSettings" = {
            "nil" = {
              "formatting" = {
                "command" = [ "${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt" ];
              };
            };
          };

          # Prettier configuration
          "prettier.semi" = true;
          "prettier.singleQuote" = true;
          "prettier.tabWidth" = 2;
          "prettier.useTabs" = false;
          "prettier.trailingComma" = "es5";

          # Java extension configuration to use environment variables
          "java.configuration.detectJdksAtStart" = true;
          "java.configuration.runtimes" = [ ];
          "java.import.gradle.java.home" = null;
          "java.import.maven.java.home" = null;
          "java.format.settings.url" =
            "https://raw.githubusercontent.com/google/styleguide/gh-pages/eclipse-java-google-style.xml";
          "java.format.settings.profile" = "GoogleStyle";

          # Docker
          "docker.dockerPath" = "${pkgs.docker}/bin/docker";

          # Remote SSH
          "remote.SSH.path" = "${pkgs.openssh}/bin/ssh";
          "remote.SSH.configFile" = "~/.ssh/config";

          # Markdown configuration
          "markdown.preview.fontSize" = 14;
          "markdown.preview.lineHeight" = 1.6;

          # Vue/JavaScript configuration
          "vue.server.petiteVue.supportHtmlFile" = true;
          "typescript.preferences.includePackageJsonAutoImports" = "auto";
          "javascript.preferences.includePackageJsonAutoImports" = "auto";

          # Vue specific settings
          "vue.autoInsert.dotValue" = true;
          "vue.inlayHints.missingRequired" = true;
          "vue.updateImportsOnFileMove.enabled" = true;

          # EditorConfig
          "editorconfig.generateAuto" = false;

          # TailwindCSS configuration
          "tailwindCSS.includeLanguages" = {
            "html" = "html";
            "javascript" = "javascript";
            "typescript" = "typescript";
            "vue" = "vue";
            "scala" = "html";
          };
          "tailwindCSS.experimental.classRegex" = [
            "class:\\s*?[\"'`]([^\"'`]*.*?)[\"'`]"
            "className:\\s*?[\"'`]([^\"'`]*.*?)[\"'`]"
            "tw`([^`]*)`"
            "tw\\.\\w+`([^`]*)`"
            "tw\\([\"'`]([^\"'`]*)[\"'`]\\)"
          ];
          "tailwindCSS.emmetCompletions" = true;

          # Headwind (Tailwind CSS class sorter)
          "headwind.runOnSave" = true;

          # Prevent auto-updates
          "extensions.autoCheckUpdates" = false;
          "update.mode" = "none";

          # Formatter configuration
          "[css]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[html]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[java]" = {
            "editor.defaultFormatter" = "redhat.java";
          };
          "[javascript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[json]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[kotlin]" = {
            "editor.defaultFormatter" = "mathiasfrohlich.kotlin";
          };
          "[markdown]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
          };
          "[python]" = {
            "editor.defaultFormatter" = "ms-python.black-formatter";
          };
          "black-formatter.path" = [ "${pkgs.black}/bin/black" ];
          "[rust]" = {
            "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          };
          "[scala]" = {
            "editor.defaultFormatter" = "scalameta.metals";
          };
          "[toml]" = {
            "editor.defaultFormatter" = "tamasfe.even-better-toml";
          };
          "[typescript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[typescriptreact]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };
          "[vue]" = {
            "editor.defaultFormatter" = "Vue.volar";
          };
          "[yaml]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
          };

          "rust-analyzer.rustfmt.extraArgs" = [ "+nightly" ];
        };
      };
    };

    home.packages = [
      (pkgs.writeShellScriptBin "code-wrapped" ''
        # Preserve important environment variables
        export SSH_AUTH_SOCK="''${SSH_AUTH_SOCK:-}"
        export SSH_AGENT_PID="''${SSH_AGENT_PID:-}"
        export GIT_ASKPASS="''${GIT_ASKPASS:-}"
        export DISPLAY="''${DISPLAY:-}"
        export XAUTHORITY="''${XAUTHORITY:-}"

        # Preserve HOME and user directories
        export HOME="''${HOME}"
        export USER="''${USER}"

        # Add our specific tools to the front of the PATH but preserve the rest
        export PATH="${vscodeOnlyPath}:${wrappersPath}:${systemToolsPath}:${homeManagerPath}:$PATH"

        # Clear Electron/Chrome flags that might cause warnings
        unset ELECTRON_OZONE_PLATFORM_HINT
        unset NIXOS_OZONE_WL

        # Use regular vscode package instead of FHS version to avoid permission issues
        exec ${pkgs.vscode}/bin/code "$@"
      '')
    ];

    programs = {
      fish.shellAliases = sharedAliases.fishAliases // {
        code = "code-wrapped";
      };

      fish.interactiveShellInit = ''
        if test "$TERM_PROGRAM" = "vscode"
          # Preserve existing PATH and prepend our tools
          set -gx PATH "${vscodeOnlyPath}:${wrappersPath}:${systemToolsPath}:${homeManagerPath}" $PATH

          # Ensure SSH agent is available
          if test -z "$SSH_AUTH_SOCK"
            if test -S "$XDG_RUNTIME_DIR/ssh-agent"
              set -gx SSH_AUTH_SOCK "$XDG_RUNTIME_DIR/ssh-agent"
            end
          end

          # Source system fish config if it exists
          if test -f /etc/fish/config.fish
            source /etc/fish/config.fish
          end
        end
      '';
    };

    xdg.desktopEntries."code" = {
      name = "Visual Studio Code";
      comment = "Code Editing. Redefined.";
      genericName = "Text Editor";
      exec = "code-wrapped %F";
      icon = "code";
      startupNotify = true;
      categories = [
        "Utility"
        "TextEditor"
        "Development"
        "IDE"
      ];
      mimeType = [
        "text/plain"
        "inode/directory"
      ];
      actions = {
        new-empty-window = {
          exec = "code-wrapped --new-window %F";
          name = "New Empty Window";
        };
      };
    };

    home.persistence."/persist/${config.home.homeDirectory}" = {
      directories = [
        ".config/Code"
        ".config/copilot-chat"
        ".config/github-copilot"
      ];
    };
  };
}
