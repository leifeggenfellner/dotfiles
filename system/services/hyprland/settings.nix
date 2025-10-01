{ pkgs, ... }:
{
  programs.hyprland.settings = {
    env = [
      "GRIMBLAST_NO_CURSOR,0"
      "HYPRCURSOR_THEME,${pkgs.capitaine-cursors}"
      "HYPRCURSOR_SIZE,16"
      "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
    ];
    exec-once = [
      "hyprpaper"
      "hyprctl setcursor capitaine-cursors-white 16"
      "wl-clip-persist --clipboard both &"
      "wl-paste --watch cliphist store &"
      "uwsm finalize"
      "[workspace 1 silent] zen"
      "[workspace 2 silent] emacsclient -c -n"
      "[workspace 8 silent] slack"
      "[workspace 9 silent] discord"
    ];

    general = {
      gaps_in = 7;
      gaps_out = 7;
      border_size = 3; # Increased for better visibility
      allow_tearing = true;
      resize_on_border = true;
      # Fixed to use standard rgb() format that actually works
      "col.active_border" = "rgb(B48EAD)";        # Magenta border
      "col.inactive_border" = "rgba(4C566A,0.5)"; # Gray with transparency
    };

    cursor.inactive_timeout = 5;
    decoration = {
      rounding = 16;
      blur = {
        enabled = true;
        size = 6;
        passes = 3;
        new_optimizations = true;
        ignore_opacity = true;
      };
    };

    layerrule = [
      "noblur,wofi"
      "ignorealpha 0,wofi"
    ];

    animations.enabled = true;
    animation = [
      "border, 1, 4, default" # Smoother border animations
      "fade, 1, 4, default"
      "windows, 1, 3, default, popin 80%"
      "workspaces, 1, 2, default, slide"
    ];
    group = {
      groupbar = {
        font_size = 10;
        gradients = false;
      };
    };
    input = {
      kb_layout = "no,us";
      kb_options = "grp:alt_shift_toggle";
    };
    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };
    misc = {
      disable_autoreload = true;
      force_default_wallpaper = 0;
      animate_mouse_windowdragging = false;
      vrr = 1;
    };

    xwayland.force_zero_scaling = true;
    debug.disable_logs = false;
  };
}
