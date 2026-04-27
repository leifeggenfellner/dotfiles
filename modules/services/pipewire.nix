_: {
  flake.nixosModules.services-pipewire = {
    security.rtkit.enable = true;

    services = {
      pulseaudio.enable = false;

      pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        wireplumber.extraConfig."wireplumber.profiles".main."monitor.libcamera" = "disabled";
      };
    };
  };
}
