_: {
  # NixOS side: full fish system config (vendor, aliases, prompt, init scripts).
  flake.nixosModules.programs-fish =
    { pkgs, ... }:
    let
      fzfConfig = ''
        set -x FZF_DEFAULT_OPTS "--preview='bat {} --color=always'" \n
        set -x SKIM_DEFAULT_COMMAND "rg --files || fd || find ."
      '';

      themeConfig = ''
        set -g theme_display_date no
        set -g theme_display_git_master_branch no
        set -g theme_nerd_fonts yes
        set -g theme_newline_cursor yes
        set -g theme_color_scheme solarized
      '';

      fishConfig =
        ''
          set fish_greeting
        ''
        + fzfConfig
        + themeConfig;

      dc = "${pkgs.docker-compose}/bin/docker-compose";
    in
    {
      programs.fish = {
        enable = true;
        vendor = {
          completions.enable = true;
          config.enable = true;
          functions.enable = true;
        };
        interactiveShellInit = ''
          eval (direnv hook fish)
          jump shell fish | source
          any-nix-shell fish --info-right | source
        '';
        shellAliases = {
          inherit dc;

          # Tool replacements
          cat = "bat";
          du = "${pkgs.ncdu}/bin/ncdu --color dark -rr -x";
          ping = "${pkgs.prettyping}/bin/prettyping";
          xdg-open = "${pkgs.mimeo}/bin/mimeo";

          # Fun
          bonsai = "cbonsai -li -t 0.02";
          matrix = "cmatrix -ab";
          pipes = "pipes-rs";

          # Navigation
          ".." = "cd ..";

          # Git alias
          gcm = "git checkout master";
          gs = "git status";
          ga = "git add";
          gaa = "git add -A";
          gm = "git commit -m";
          gp = "git push";
          gc = "git checkout";

          # Maven alias
          mvncp = "mvn clean package";
          mvnci = "mvn clean install";

          # Docker
          dps = "${dc} ps";
          dcd = "${dc} down --remove-orphans";
          drm = "docker images -a -q | xargs docker rmi -f";

          # Nix
          nixgc = "nix-collect-garbage";
          nixgcd = "sudo nix-collect-garbage -d";
          update = "nix flake update";
          supdate = "sudo nix flake update";
          upgrade = "sudo nixos-rebuild switch --flake";

          # Locations
          dot = "cd ~/Sources/dotfiles";
          doc = "cd ~/Documents";
          work = "cd ~/Projects/workspace";
          tod = "cd ~/Projects/workspace/worksetup";
          be = "cd ~/Projects/workspace/nmkp/";
          fe = "cd ~/Projects/workspace/nmkp/modules/nmkp-app-core/";
        };
        shellInit = fishConfig;
      };
    };

  # home-manager side: per-user plugins, useful packages, persistence.
  flake.homeModules.programs-fish =
    { pkgs, ... }:
    let
      fenv = {
        inherit (pkgs.fishPlugins.foreign-env) src;
        name = "foreign-env";
      };
    in
    {
      home = {
        packages = with pkgs; [
          any-nix-shell
          dive
          duf
          fd
          git
          jump
          ncdu
        ];

        persistence."/persist/" = {
          directories = [
            ".local/share/fish"
            ".jump"
          ];
        };
      };

      programs.fish = {
        enable = true;
        plugins = [ fenv ];

        interactiveShellInit = ''
          set -p fish_complete_path ${pkgs.fish}/share/fish/completions
          set -p fish_complete_path ${pkgs.git}/share/fish/vendor_completions.d
        '';

        functions = {
          undo = {
            wraps = "git reset";
            body = ''
              git reset HEAD~1 --mixed
            '';
          };

          res = {
            wraps = "git reset --hard";
            body = ''
              git reset --hard
            '';
          };

          fixup = {
            wraps = "git commit --amend";
            body = ''
              git reset --soft HEAD~$argv[1]
              git commit --amend -C HEAD
            '';
          };

          loc = {
            wraps = "git ls-files";
            body = ''
              git ls-files | ${pkgs.ripgrep}/bin/rg "$argv[1]" | xargs wc -l
            '';
          };
        };
      };
    };
}
