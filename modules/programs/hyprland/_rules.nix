{ lib }:
let
  floatingClasses = [
    "^(Rofi)$"
    "^(eww)$"
    "^(Gimp-2.10)$"
    "^(org.gnome.Calculator)$"
    "^(org.gnome.Calendar)$"
    "^(gnome-system-monitor)$"
    "^(pavucontrol)$"
    "^(nm-connection-editor)$"
    "^(Color Picker)$"
    "^(Network)$"
    "^(pcmanfm)$"
    "^(com.github.flxzt.rnote)$"
    "^(xdg-desktop-portal)$"
    "^(xdg-desktop-portal-gnome)$"
    "^(transmission-gtk)$"
    "^(org.kde.kdeconnect-settings)$"
    "^(org.pulseaudio.pavucontrol)$"
  ];
  floatingTitles = [ "^(Spotify Premium)$" "^(Spotify)$" "^(spotify_player)$" "^(yazi)$" "^(btop)$" ];
  floatRule = field: pattern: width: height: {
    match.${field} = pattern;
    float = true;
    size = [ width height ];
    center = true;
  };
in
{
  workspace_rule = { workspace = "special:magic"; gaps_in = 20; gaps_out = 40; };

  layer_rule = map
    (namespace: { match.namespace = namespace; blur = true; ignore_alpha = 0; })
    [ "^(wofi)$" "^(waybar)$" "^(swaync-notification-window)$" "^(swaync-control-center)$" ];

  window_rule = [
    {
      name = "alert-dialogs-no-initial-focus";
      match.title = ".*([Aa]lert|[Dd]ialog|[Nn]otification|[Pp]opup).*";
      suppress_event = "activate activatefocus";
      focus_on_activate = false;
      no_initial_focus = true;
    }
  ]
  ++ map (pattern: floatRule "class" pattern "monitor_w*0.5" "monitor_h*0.7") floatingClasses
  ++ map (pattern: floatRule "title" pattern "monitor_w*0.5" "monitor_h*0.7") floatingTitles
  ++ [
    (floatRule "title" "^(wallpaper-picker)$" "monitor_w*0.6" "monitor_h*0.8")
    { match.class = "^(code|Code)$"; workspace = "1"; }
    { match.class = "^(Alacritty|alacritty|foot)$"; workspace = "2"; }
    { match.class = "^(zen|ZenBrowser)$"; workspace = "3"; }
    { match.class = "^(Slack)$"; workspace = "4"; }
    { match.class = "^(discord)$"; workspace = "4"; }
    { match.class = "^(spotify)$"; workspace = "5"; }
    { match.class = "^(btop|htop|nvtop|MissionCenter)$"; workspace = "6"; }
    { match.class = "^(zen|ZenBrowser)$"; opacity = "1.0 override 1.0 override"; }
  ];
}
