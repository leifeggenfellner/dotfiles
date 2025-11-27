{ pkgs
, ...
}:
let
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
      "ssh://git@github.com". pushInsteadOf = "gh:";
    };

    # GitHub helper
    github = {
      user = "leifeggenfellner";
    };

    # User identity
    user = {
      name = "leifeggenfellner";
      email = "eggenfellner@protonmail.com";
    };

    # Aliases (git subcommands)
    alias = {
      sw = "switch";
      swc = "switch -c";
      co = "checkout";
      cma = "commit -am";
      p = "push";
      st = "status -sb";
      lg1 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)' --all";
      lg2 = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold cyan)%aD%C(reset) %C(bold green)(%ar)%C(reset)%C(bold yellow)%d%C(reset)%n''          %C(white)%s%C(reset) %C(dim white)- %an%C(reset)' --all";
      lg = "! git lg1";
      ll = "log --oneline";
      last = "log -1 HEAD --stat";
      cm = "commit -m";
      rv = "remote -v";
      d = "diff";
      gl = "config --global -l";
      se = "! git rev-list --all | xargs git grep -F";
      cob = "checkout -b";
      del = "branch -D";
      br = "branch --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(contents:subject) %(color:green)(%(committerdate:relative)) [%(authorname)]' --sort=-committerdate";
      save = "! git add -A && git commit -m 'chore: commit save point'";
      done = "!git push origin HEAD";
      ls = "ls-files -s";
      staash = "stash --all";
      graph = "log --decorate --oneline --graph";
      dc = "diff --cached";
      amend = "commit --amend -m";
    };
  };
in
{
  home. packages = with pkgs; [
    diff-so-fancy
    git-crypt
    hub
    tig
  ];

  programs.git = {
    enable = true;

    settings = gitConfig;

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
        condition = "hasconfig:remote.*. url:ssh://git@github.com:HNIKT-Tjenesteutvikling-Systemutvikling/**";
        contents = {
          user = {
            name = "leifeggenfellner";
            email = "eggenfellner@protonmail.com";
          };
        };
      }
    ];

    ignores = [
      "*.bloop"
      "*.bsp"
      "*.metals"
      "*.metals.sbt"
      "*metals.sbt"
      "*.direnv"
      "*.envrc"
      "*hie. yaml"
      "*.mill-version"
      "*.jvmopts"
    ];
  };
}
