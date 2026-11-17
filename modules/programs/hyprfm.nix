{ inputs, ... }: {
  # HyprFM shells out for previews, metadata and devices; gvfs (on via
  # greetd) serves Trash and network mounts, usbmuxd serves iPhones.
  flake.nixosModules.programs-hyprfm =
    { config, lib, ... }:
    lib.mkIf (config.environment.desktop.windowManager == "hyprland") {
      services.usbmuxd.enable = true;
      # gvfs backends look their mount descriptions up under /usr/share/gvfs.
      systemd.tmpfiles.rules = [
        "L+ /usr/share/gvfs - - - - ${config.services.gvfs.package}/share/gvfs"
      ];
    };

  flake.homeModules.programs-hyprfm =
    { osConfig, pkgs, lib, ... }:
    lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
      home.packages = [
        inputs.hyprfm.packages.${pkgs.stdenv.hostPlatform.system}.default
        pkgs.exiftool
        pkgs.ffmpeg
        pkgs.libimobiledevice
        pkgs.ntfs3g
        pkgs.rclone
        pkgs.usbmuxd
      ];

      # VS Code also claims inode/directory, so the folder handler is explicit.
      xdg.mimeApps.defaultApplications."inode/directory" = "hyprfm.desktop";
    };
}
