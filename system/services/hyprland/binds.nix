let
  mainMod = "SUPER";
  SECONDARY = "SHIFT";
  TERTIARY = "CTRL";

  toggle =
    program:
    let
      prog = builtins.substring 0 14 program;
    in
    "pkill ${prog} || uwsm app -- ${program}";

  runOnce = program: "pgrep ${program} || uwsm app -- ${program}";
  launch = program: "uwsm app -- ${program}";
in
{
  programs.hyprland.settings = {
    # Launchers
    bind = [
      "${mainMod}, Return, exec, ${launch "alacritty"}"
      "${mainMod}, D, exec, ${toggle "wofi --show drun"}"
      "${mainMod}, B, exec, ${toggle "alacritty -t btop -e btm"}"
      "${mainMod}, R, exec, ${toggle "alacritty -t ranger -e ranger"}"
      "${mainMod}, S, exec, ${launch "spotify"}"
      "${mainMod} ${SECONDARY}, D, exec, ${runOnce "pcmanfm"}"

      # Lockscreen
      "${mainMod} ${SECONDARY}, L, exec, ${runOnce "hyprlock"}"

      # Screenshot
      "${mainMod} ${SECONDARY}, P, exec, ${runOnce "grimblast --notify copy area"}"

      # Scratchpads
      "${mainMod} ${SECONDARY}, T, movetoworkspace, special"
      "${mainMod}, t, togglespecialworkspace"

      # Bindings
      "${mainMod} ${SECONDARY} ${TERTIARY}, Q, exit"
      "${mainMod}, Q, killactive"
      "${mainMod}, F, togglefloating"
      "${mainMod}, G, fullscreen"
      "${mainMod}, P, togglesplit"

      # Move focus with mainMod + arrow keys
      "${mainMod}, k, movefocus, u"
      "${mainMod}, j, movefocus, d"
      "${mainMod}, l, movefocus, r"
      "${mainMod}, h, movefocus, l"

      # Switch workspaces with mainMod + [0-9]
      "${mainMod}, left,  exec, hyprctl dispatch workspace e-1"
      "${mainMod}, right, exec, hyprctl dispatch workspace e+1"
      "${mainMod}, 1, exec, hyprctl dispatch workspace 1"
      "${mainMod}, 2, exec, hyprctl dispatch workspace 2"
      "${mainMod}, 3, exec, hyprctl dispatch workspace 3"
      "${mainMod}, 4, exec, hyprctl dispatch workspace 4"
      "${mainMod}, 5, exec, hyprctl dispatch workspace 5"
      "${mainMod}, 6, exec, hyprctl dispatch workspace 6"
      "${mainMod}, 7, exec, hyprctl dispatch workspace 7"
      "${mainMod}, 8, exec, hyprctl dispatch workspace 8"
      "${mainMod}, 9, exec, hyprctl dispatch workspace 9"

      # Move active window to workspace
      "${mainMod} ${SECONDARY}, right, exec, hyprctl dispatch movetoworkspace e+1"
      "${mainMod} ${SECONDARY}, left, exec, hyprctl dispatch movetoworkspace e-1"
      "${mainMod} ${SECONDARY}, 1, exec, hyprctl dispatch movetoworkspace 1"
      "${mainMod} ${SECONDARY}, 2, exec, hyprctl dispatch movetoworkspace 2"
      "${mainMod} ${SECONDARY}, 3, exec, hyprctl dispatch movetoworkspace 3"
      "${mainMod} ${SECONDARY}, 4, exec, hyprctl dispatch movetoworkspace 4"
      "${mainMod} ${SECONDARY}, 5, exec, hyprctl dispatch movetoworkspace 5"
      "${mainMod} ${SECONDARY}, 6, exec, hyprctl dispatch movetoworkspace 6"
      "${mainMod} ${SECONDARY}, 7, exec, hyprctl dispatch movetoworkspace 7"
      "${mainMod} ${SECONDARY}, 8, exec, hyprctl dispatch movetoworkspace 8"
      "${mainMod} ${SECONDARY}, 9, exec, hyprctl dispatch movetoworkspace 9"

      # Volume keys
      ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

      # Media keys
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPrev, exec, playerctl previous"

      # Brightness keys
      ", XF86MonBrightnessUp,   exec, brightnessctl set +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
    ];

    # Window
    binde = [
      "${mainMod} ${TERTIARY}, k, resizeactive, 0 -20"
      "${mainMod} ${TERTIARY}, j, resizeactive, 0 20"
      "${mainMod} ${TERTIARY}, l, resizeactive, 20 0"
      "${mainMod} ${TERTIARY}, h, resizeactive, -20 0"
      "${mainMod} ALT,  k, moveactive, 0 -20"
      "${mainMod} ALT,  j, moveactive, 0 20"
      "${mainMod} ALT,  l, moveactive, 20 0"
      "${mainMod} ALT,  h, moveactive, -20 0"
    ];

    # Move/resize windows with mainMod + LMB/RMB and dragging
    bindm = [
      "${mainMod}, mouse:272, movewindow"
      "${mainMod}, mouse:273, resizewindow"
    ];
  };
}
