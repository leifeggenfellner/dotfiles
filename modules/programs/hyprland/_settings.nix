{ style, colors }:
{
  config = {
    general = {
      gaps_in = style.gapsInner;
      gaps_out = style.gapsOuter;
      border_size = style.borderWidth;
      allow_tearing = true;
      resize_on_border = true;
      col = {
        active_border = colors.activeBorder;
        inactive_border = colors.inactiveBorder;
      };
      hover_icon_on_border = true;
      extend_border_grab_area = 15;
    };
    cursor = {
      inactive_timeout = 3;
      no_hardware_cursors = 0;
      enable_hyprcursor = true;
    };
    decoration = {
      rounding = style.rounding;
      blur = {
        enabled = true;
        size = style.blurSize;
        passes = style.blurPasses;
        new_optimizations = true;
        ignore_opacity = true;
        xray = false;
        contrast = style.blurContrast;
        brightness = style.blurBrightness;
        noise = style.blurNoise;
      };
      active_opacity = style.opacityActive;
      inactive_opacity = style.opacityInactive;
      fullscreen_opacity = 1.0;
    };
    animations.enabled = true;
    input = {
      kb_layout = "no";
      follow_mouse = 1;
      mouse_refocus = true;
      sensitivity = 0.0;
      accel_profile = "adaptive";
      touchpad = {
        natural_scroll = true;
        disable_while_typing = true;
        tap_to_click = true;
        middle_button_emulation = true;
      };
    };
    group = {
      groupbar = {
        font_size = style.fontSizeSmall;
        gradients = true;
        render_titles = true;
        scrolling = true;
      };
      col = {
        border_active = colors.activeBorder;
        border_inactive = colors.inactiveBorder;
      };
    };
    dwindle = {
      preserve_split = true;
      force_split = 1;
      default_split_ratio = 1.2;
      smart_split = false;
      smart_resizing = false;
      use_active_for_splits = true;
    };
    misc = {
      disable_autoreload = false;
      force_default_wallpaper = 0;
      animate_mouse_windowdragging = true;
      animate_manual_resizes = true;
      vrr = 1;
      focus_on_activate = true;
      mouse_move_focuses_monitor = true;
      enable_swallow = true;
      swallow_regex = "^(foot|alacritty|kitty)$";
    };
    xwayland.force_zero_scaling = true;
    debug.disable_logs = false;
  };

  env = [
    { _args = [ "GRIMBLAST_NO_CURSOR" "0" ]; }
    { _args = [ "HYPRCURSOR_THEME" style.cursorName ]; }
    { _args = [ "HYPRCURSOR_SIZE" (toString style.cursorSize) ]; }
    { _args = [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]; }
  ];

  curve = [
    { _args = [ "wind" { type = "bezier"; points = [ [ 0.05 0.9 ] [ 0.1 1.05 ] ]; } ]; }
    { _args = [ "winIn" { type = "bezier"; points = [ [ 0.1 1.1 ] [ 0.1 1.1 ] ]; } ]; }
    { _args = [ "winOut" { type = "bezier"; points = [ [ 0.3 (-0.3) ] [ 0 1 ] ]; } ]; }
    { _args = [ "liner" { type = "bezier"; points = [ [ 1 1 ] [ 1 1 ] ]; } ]; }
    { _args = [ "overshot" { type = "bezier"; points = [ [ 0.13 0.99 ] [ 0.29 1.1 ] ]; } ]; }
  ];

  animation = [
    { leaf = "windows"; enabled = true; speed = 6; bezier = "wind"; style = "slide"; }
    { leaf = "windowsIn"; enabled = true; speed = 6; bezier = "winIn"; style = "slide"; }
    { leaf = "windowsOut"; enabled = true; speed = 5; bezier = "winOut"; style = "slide"; }
    { leaf = "windowsMove"; enabled = true; speed = 5; bezier = "wind"; style = "slide"; }
    { leaf = "border"; enabled = true; speed = 10; bezier = "liner"; }
    { leaf = "fade"; enabled = true; speed = 10; bezier = "default"; }
    { leaf = "layers"; enabled = true; speed = 4; bezier = "wind"; style = "slide"; }
    { leaf = "layersIn"; enabled = true; speed = 4; bezier = "winIn"; style = "slide"; }
    { leaf = "layersOut"; enabled = true; speed = 3; bezier = "winOut"; style = "fade"; }
    { leaf = "workspaces"; enabled = true; speed = 6; bezier = "overshot"; style = "slidevert"; }
    { leaf = "specialWorkspace"; enabled = true; speed = 6; bezier = "default"; style = "slidevert"; }
  ];
}
