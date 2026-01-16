{
  programs.hyprland.settings = {
    windowrule = [
      # Floating windows with sizing and centering
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(Rofi)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(eww)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(Gimp-2.10)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(org.gnome.Calculator)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(org.gnome.Calendar)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(gnome-system-monitor)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(pavucontrol)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(nm-connection-editor)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(Color Picker)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(Network)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(pcmanfm)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(com.github.flxzt.rnote)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(xdg-desktop-portal)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(xdg-desktop-portal-gnome)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(transmission-gtk)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(org.kde.kdeconnect-settings)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:class ^(org.pulseaudio.pavucontrol)$"

      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(Spotify Premium)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(Spotify)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(spotify_player)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(ranger)$"
      "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(btop)$"

      # Opacity rules
      "opacity 0.91 override 0.73 override, match:class ^(Emacs)$"

      # Workspace assignments
      "workspace 1, match:class ^(code|Code)$"
      "workspace 2, match:class ^(Alacritty|alacritty)$"
      "workspace 3, match:class ^(zen|ZenBrowser)$"
      "workspace 4, match:class ^(Slack)$"
      "workspace 4, match:class ^(discord)$"
      "workspace 5, match:class ^(spotify)$"
      "workspace 6, match:class ^(btop|htop|nvtop|MissionCenter)$"
    ];
  };
}
