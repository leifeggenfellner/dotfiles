_: {
  flake.homeModules.programs-core =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        acpi # battery info
        asciiquarium-transparent # asciiquarium
        brightnessctl # control screen brightness
        cacert # ca certificates
        dconf2nix # dconf (gnome) files to nix converter
        ffmpegthumbnailer # thumbnailer for video files
        gum # glamorous shell scripts
        headsetcontrol # control logitech headsets
        imv # image viewer
        imagemagick # image manipulation
        killall # kill processes by name
        libsecret # secret management
        mediainfo # media information
        nix-index # locate packages containing certain nixpkgs
        nix-output-monitor # nom: monitor nix commands
        nix-prefetch-git # prefetch git sources
        ouch # painless compression and decompression for your terminal
        paprefs # pulseaudio preferences
        pgadmin4-desktopmode # db viewer
        playerctl # media player control
        pulseaudio # pulseaudio
        pavucontrol # pulseaudio volume control
        prettyping # a nicer ping
        poppler # pdf tools
        powertop # power stuff
        pipewire # control volume
        pipes-rs # terminal pipes eye candy
        cbonsai # bonsai trees in terminal
        cmatrix # matrix rain in terminal
        rage # encryption tool for secrets management
        ripgrep # fast grep
        statix #linting
        tldr # summary of a man page
        tree # display files in a tree view
        spicetify-cli # Customize Spotify client
        unzip # unzip files
        xarchiver # archive manager
        zip # zip files
      ];
    };
}
