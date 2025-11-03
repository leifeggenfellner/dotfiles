{ pkgs
, ...
}:
let
  rg = "${pkgs.ripgrep}/bin/rg";

  gitConfig = {
    core = {
      editor = "nvim";
    };
    init = {
      defaultBranch = "main";
    };
    color = {
      ui = "auto";
    };
    help = {
      autocorrect = 20;
    };
    fetch = {
      prune = true;
    };
    pull = {
      rebase = true;
    };
    push = {
      default = "upstream";
      autoSetupRemote = true;
    };

    # Rebase behaviour
    rebase = {
      updateRefs = true;
      autoSquash = true;
      autoStash = true;
    };

    # Difftool
    diff = {
      tool = "nvimdiff";
    };
    difftool = {
      prompt = false;
      nvimdiff = {
        cmd = "nvim -d $LOCAL $REMOTE";
      };
    };

    # URL rewrites
    url = {
      "https://github.com/".insteadOf = "gh:";
      "ssh://git@github.com".pushInsteadOf = "gh:";
    };

    # GitHub helper
    github = {
      user = "leifeggenfellner";
    };

    # User identity (moved here from deprecated top-level keys)
    user = {
      name = "leifeggenfellner";
      email = "eggenfellner@protonmail.com";
    };

    # Aliases (now under `alias` in settings)
    alias = {
      p = "push";
      st = "status -sb";
      lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
      lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
      lg = "!git lg1";
      ll = "log --oneline";
      last = "log -1 HEAD --stat";
      cm = "commit -m";
      rv = "remote -v";
      d = "diff";
      gl = "config --global -l";
      se = "!git rev-list --all | xargs git grep -F";
      sw = "switch";
      cob = "checkout -b";
      del = "branch -D";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      save = "!git add -A && git commit -m 'chore: commit save point'";
      undo = "reset HEAD~1 --mixed";
      res = "!git reset --hard";
      done = "!git push origin HEAD";
      ls = "ls-files -s";
      swc = "switch -c";
      cma = "commit --amend";
      prune-branches = "!git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D";
      show-prunable = "!git fetch --prune && git branch -vv | grep ': gone]'";
      amend = "commit --amend -m";
      fixup = "!f(){ git reset --soft HEAD~${1} && git commit --amend -C HEAD; };f";
      loc = "!f(){ git ls-files | ${rg} \"\\.${1}\" | xargs wc -l; };f";
      staash = "stash --all";
      graph = "log --decorate --oneline --graph";
      co = "checkout";
      ca = "commit -am";
      dc = "diff --cached";
    };
  };
in
{
  home.packages = with pkgs; [
    diff-so-fancy
    git-crypt
    hub
    tig
  ];

  programs.git = {
    enable = true;

    # All git configuration now lives under `settings` (was `extraConfig`)
    settings = gitConfig;

    # Keep your includes at top-level if you still want per-repo or condition-based includes.
    includes = [
      {
        condition = "gitdir:~/Workflow/";
        contents = {
          user = {
            name = "leifeggenfellner";
            email = "eggenfellner@protonmail.com";
          };
        };
      }
      {
        condition = "hasconfig:remote.*.url:ssh://git@github.com:HNIKT-Tjenesteutvikling-Systemutvikling/**";
        contents = {
          user = {
            name = "leifeggenfellner";
            email = "eggenfellner@protonmail.com";
          };
        };
      }
    ];

    # Keeps your ignores list — this option is still valid on the top-level programs.git
    ignores = [
      "*.bloop"
      "*.bsp"
      "*.metals"
      "*.metals.sbt"
      "*metals.sbt"
      "*.direnv"
      "*.envrc"
      "*hie.yaml"
      "*.mill-version"
      "*.jvmopts"
    ];
  };
}
