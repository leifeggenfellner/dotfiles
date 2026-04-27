_: {
  flake.homeModules.programs-fzf = {
    programs.fzf = {
      enable = true;
      defaultCommand = "fd --type file --follow";
      defaultOptions = [ "--height 20%" ];
      fileWidgetCommand = "fd --type file --follow";
    };
  };
}
