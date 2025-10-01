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
      "[workspace 3 silent] zen"
      "[workspace 2 silent] alacritty"
      "[workspace 4 silent] slack"
    ];

    general = {
      gaps_in = 7;
      gaps_out = 7;
      border_size = 2;
      allow_tearing = true;
      resize_on_border = true;
      "col.active_border" = "rgb(B48EAD) rgb(89B4FA) rgb(74C7EC) 45deg"; # Magenta to blue gradient
      "col.inactive_border" = "rgb(313244)";
      # Border hover effects
      hover_icon_on_border = true;
      extend_border_grab_area = 15;
    };

    cursor = {
      inactive_timeout = 3;
      no_hardware_cursors = false;
      enable_hyprcursor = true;
    };

    decoration = {
      rounding = 16;

      blur = {
        enabled = true;
        size = 8;
        passes = 4;
        new_optimizations = true;
        ignore_opacity = true;
        xray = false;
        contrast = 1.1;
        brightness = 1.0;
        noise = 0.02;
      };

      active_opacity = 1.0;
      inactive_opacity = 0.95;
      fullscreen_opacity = 1.0;
    };

    layerrule = [
      "blur, wofi"
      "ignorealpha 0, wofi"
      "blur, waybar"
      "ignorealpha 0, waybar"
      "blur, notifications"
      "ignorealpha 0, notifications"
    ];

    animations = {
      enabled = true;
    };

    # Define beziers and animations
    bezier = [
      "wind, 0.05, 0.9, 0.1, 1.05"
      "winIn, 0.1, 1.1, 0.1, 1.1"
      "winOut, 0.3, -0.3, 0, 1"
      "liner, 1, 1, 1, 1"
      "overshot, 0.13, 0.99, 0.29, 1.1"
    ];

    animation = [
      # Window animations with custom beziers
      "windows, 1, 6, wind, slide"
      "windowsIn, 1, 6, winIn, slide"
      "windowsOut, 1, 5, winOut, slide"
      "windowsMove, 1, 5, wind, slide"

      # Border animations
      "border, 1, 10, liner"
      "borderangle, 1, 60, liner, loop" # Animated gradient rotation

      # Fade effects
      "fade, 1, 10, default"

      # Workspace animations with overshot
      "workspaces, 1, 6, overshot, slidevert"

      # Special effects
      "specialWorkspace, 1, 6, default, slidevert"
    ];

    input = {
      kb_layout = "no,us";
      kb_options = "grp:alt_shift_toggle";

      follow_mouse = 1;
      mouse_refocus = true;
      sensitivity = 0.0;
      accel_profile = "adaptive";

      # Touchpad improvements
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        tap-to-click = true;
        middle_button_emulation = true;
      };
    };

    group = {
      groupbar = {
        font_size = 10;
        gradients = true;
        render_titles = true;
        scrolling = true;
      };

      # Group border colors
      "col.border_active" = "rgb(B48EAD)";
      "col.border_inactive" = "rgb(313244)";
    };

    dwindle = {
      pseudotile = true;
      preserve_split = true;
      force_split = 0;
      default_split_ratio = 1.2;
      smart_split = true;
      smart_resizing = true;
    };

    misc = {
      disable_autoreload = true;
      force_default_wallpaper = 0;
      animate_mouse_windowdragging = true;
      animate_manual_resizes = true;
      vrr = 1;

      # Window focus settings
      focus_on_activate = true;
      mouse_move_focuses_monitor = true;

      # Visual effects
      enable_swallow = true;
      swallow_regex = "^(foot|alacritty|kitty)$";

      # Removed new_window_takes_focus and allow_session_lock_restore as they don't exist
    };

    # Fixed window rules - use windowrulev2 for better regex support
    windowrulev2 = [
      "float, class:^(pavucontrol)$"
      "float, class:^(blueman-manager)$"
      "float, class:^(nm-connection-editor)$"
      "float, class:^(file-roller)$"
      "size 800 600, class:^(pavucontrol)$"
      "center, class:^(pavucontrol)$"
      "opacity 0.95 0.85, class:^(alacritty)$"
      "opacity 0.95 0.85, class:^(foot)$"
    ];

    # Simplified workspace rules
    workspace = [
      "special:magic, gapsin:20, gapsout:40"
    ];

    xwayland.force_zero_scaling = true;
    debug.disable_logs = false;
  };
}
