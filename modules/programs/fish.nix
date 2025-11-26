{ pkgs, config, ... }:
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
      eza
      fd
      jump
      ncdu
      nitch
    ];

    persistence."/persist/${config.home.homeDirectory}" = {
      directories = [
        ".local/share/fish"
        ".jump"
      ];
    };
  };

  programs.fish = {
    enable = true;
    plugins = [ fenv ];

    functions = {
      sw = {
        wraps = "git switch";
        body = ''
          git switch $argv
        '';
      };

      swc = {
        wraps = "git switch -c";
        body = ''
          git switch -c $argv
        '';
      };

      co = {
        wraps = "git checkout";
        body = ''
          git checkout $argv
        '';
      };

      cma = {
        wraps = "git commit -am";
        body = ''
          git commit -am $argv
        '';
      };

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
}
