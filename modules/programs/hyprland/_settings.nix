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
      inherit (style) rounding;
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
      # Let a crashed or relaunched lock client take the session lock
      # back (the rice lock screen relies on this when re-locking).
      allow_session_lock_restore = true;
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

  # Shared with the rice adapter, which restores these leaves when a
  # theme's compositor motion is switched away (D-047).
  inherit (import ./_animations.nix) curve animation;
}
