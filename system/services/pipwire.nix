{
  # Enable rtkit for real-time scheduling (required for audio)
  security.rtkit.enable = true;

  services = {
    # Make sure PulseAudio service is disabled
    pulseaudio.enable = false;

    # Enable pipewire
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true; # PulseAudio compatibility layer
      wireplumber.extraConfig."wireplumber.profiles".main."monitor.libcamera" = "disabled";
    };
  };
}
