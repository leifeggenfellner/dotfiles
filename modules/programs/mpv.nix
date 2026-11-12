_: {
  flake.homeModules.programs-mpv =
    { osConfig, lib, ... }:
    let
      videoTypes = [
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/quicktime"
        "video/x-msvideo"
        "video/x-flv"
        "video/x-ms-wmv"
        "video/mpeg"
        "video/ogg"
        "video/3gpp"
        "video/3gpp2"
        "video/mp2t"
        "video/x-m4v"
      ];
    in
    lib.mkIf osConfig.environment.desktop.enable {
      programs.mpv.enable = true;

      xdg.mimeApps = {
        enable = true;
        defaultApplications = lib.genAttrs videoTypes (_: "mpv.desktop") // {
          # Previously set by hand in an unmanaged mimeapps.list; keep it now
          # that Home Manager owns the file.
          "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";
        };
      };
    };
}
