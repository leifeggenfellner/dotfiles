_: {
  flake.homeModules.base =
    { osConfig, pkgs, ... }:
    let
      username = "leif";
      homeDirectory = "/home/${username}";
      configHome = "${homeDirectory}/.config";

      # With secrets enabled, gh authenticates from the sops-managed token
      # instead of needing `gh auth login` on every machine. Scoped to gh
      # rather than exported session-wide.
      ghTokenPath = osConfig.sops.secrets."github/token".path;
      ghPackage =
        if osConfig.secrets.enable then
          pkgs.symlinkJoin
            {
              name = "gh-with-token";
              meta.mainProgram = "gh";
              paths = [ pkgs.gh ];
              nativeBuildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                wrapProgram $out/bin/gh --run '
                  if [ -r "${ghTokenPath}" ]; then
                    export GH_TOKEN="$(< "${ghTokenPath}")"
                  fi'
              '';
            }
        else
          pkgs.gh;
    in
    {
      programs = {
        home-manager.enable = true;
        gh = {
          enable = true;
          package = ghPackage;
          settings.git_protocol = "ssh";
        };
      };

      xdg = {
        inherit configHome;
        enable = true;
      };

      home = {
        inherit username homeDirectory;
        stateVersion = "26.05";
      };

      systemd.user.startServices = "sd-switch";
      news.display = "silent";
    };
}
