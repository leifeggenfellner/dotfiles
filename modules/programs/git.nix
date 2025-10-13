{ pkgs
, ...
}:
let
  gitConfig = {
    core = {
      editor = "nvim";
    };
    init.defaultBranch = "main";
    color.ui = "auto";
    help.autocorrect = 20;
    fetch.prune = true;
    pull.rebase = true;
    push.default = "upstream";
    push.autoSetupRemote = true;
    rebase = {
      updateRefs = true;
      autoSquash = true;
      autoStash = true;
    };
    diff = {
      tool = "nvimdiff";
    };
    difftool = {
      prompt = false;
      nvimdiff.cmd = "nvim -d $LOCAL $REMOTE";
    };
    url = {
      "https://github.com/".insteadOf = "gh:";
      "ssh://git@github.com".pushInsteadOf = "gh:";
    };
    github.user = "leifeggenfellner";
  };

  rg = "${pkgs.ripgrep}/bin/rg";
in
{
  home.packages = with pkgs.gitAndTools; [
    diff-so-fancy # git diff with colors
    git-crypt # git files encryption
    hub # github command-line client
    tig # diff and commit view
  ];

  programs.git = {
    enable = true;
    aliases = {
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
      fixup = "!f(){ git reset --soft HEAD~\${1} && git commit --amend -C HEAD; };f";
      loc = "!f(){ git ls-files | ${rg} \"\\.\${1}\" | xargs wc -l; };f";
      staash = "stash --all";
      graph = "log --decorate --oneline --graph";
      co = "checkout";
      ca = "commit -am";
      dc = "diff --cached";
    };
    extraConfig = gitConfig;
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
    userEmail = "eggenfellner@protonmail.com";
    userName = "leifeggenfellner";

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
  }
  // (pkgs.sxm.git or { });
}
