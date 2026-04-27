{ inputs, ... }: {
  flake.nixosModules.services-hyprland =
    { lib, pkgs, config, ... }:
    {
      imports = [
        inputs.hyprland.nixosModules.default
      ];

      config = lib.mkIf (config.environment.desktop.windowManager == "hyprland") {
        environment = {
          systemPackages = [
            inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
          ];
          pathsToLink = [ "/share/icons" ];
          variables.NIXOS_OZONE_WL = "1";
        };

        programs = {
          hyprland = {
            enable = true;
            withUWSM = true;
            package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
            plugins = with inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}; [
            ];

            settings =
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
                # === Settings ===
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
                  "setup-monitors"
                  "handle-monitor &"
                ];

                general = {
                  gaps_in = 7;
                  gaps_out = 7;
                  border_size = 2;
                  allow_tearing = true;
                  resize_on_border = true;
                  "col.active_border" = "rgb(B48EAD) rgb(89B4FA) rgb(74C7EC) 45deg";
                  "col.inactive_border" = "rgb(313244)";
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
                  "blur on, match:namespace ^(wofi)$"
                  "ignore_alpha 0, match:namespace ^(wofi)$"
                  "blur on, match:namespace ^(waybar)$"
                  "ignore_alpha 0, match:namespace ^(waybar)$"
                  "blur on, match:namespace ^(notifications)$"
                  "ignore_alpha 0, match:namespace ^(notifications)$"
                ];

                animations.enabled = true;

                bezier = [
                  "wind, 0.05, 0.9, 0.1, 1.05"
                  "winIn, 0.1, 1.1, 0.1, 1.1"
                  "winOut, 0.3, -0.3, 0, 1"
                  "liner, 1, 1, 1, 1"
                  "overshot, 0.13, 0.99, 0.29, 1.1"
                ];

                animation = [
                  "windows, 1, 6, wind, slide"
                  "windowsIn, 1, 6, winIn, slide"
                  "windowsOut, 1, 5, winOut, slide"
                  "windowsMove, 1, 5, wind, slide"
                  "border, 1, 10, liner"
                  "borderangle, 1, 60, liner, loop"
                  "fade, 1, 10, default"
                  "workspaces, 1, 6, overshot, slidevert"
                  "specialWorkspace, 1, 6, default, slidevert"
                ];

                input = {
                  kb_layout = "no";
                  follow_mouse = 1;
                  mouse_refocus = true;
                  sensitivity = 0.0;
                  accel_profile = "adaptive";

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
                  "col.border_active" = "rgb(B48EAD)";
                  "col.border_inactive" = "rgb(313244)";
                };

                dwindle = {
                  pseudotile = true;
                  preserve_split = true;
                  force_split = 1;
                  default_split_ratio = 1.2;
                  smart_split = false;
                  smart_resizing = false;
                  use_active_for_splits = true;
                };

                misc = {
                  disable_autoreload = true;
                  force_default_wallpaper = 0;
                  animate_mouse_windowdragging = true;
                  animate_manual_resizes = true;
                  vrr = 1;
                  focus_on_activate = true;
                  mouse_move_focuses_monitor = true;
                  enable_swallow = true;
                  swallow_regex = "^(foot|alacritty|kitty)$";
                };

                workspace = [
                  "special:magic, gapsin:20, gapsout:40"
                ];

                xwayland.force_zero_scaling = true;
                debug.disable_logs = false;

                # === Binds ===
                bind = [
                  "${mainMod}, Return, exec, ${launch "alacritty"}"
                  "${mainMod}, D, exec, ${toggle "wofi --show drun"}"
                  "${mainMod}, B, exec, ${toggle "alacritty -t btop -e btm"}"
                  "${mainMod}, R, exec, ${toggle "alacritty -t ranger -e ranger"}"
                  "${mainMod}, S, exec, ${launch "spotify"}"
                  "${mainMod} ${SECONDARY}, D, exec, ${runOnce "pcmanfm"}"

                  "${mainMod} ${SECONDARY}, L, exec, ${runOnce "lock-screen"}"

                  "${mainMod} ${SECONDARY}, P, exec, ${runOnce "grimblast --notify copy area"}"

                  "${mainMod} ${SECONDARY}, T, movetoworkspace, special"
                  "${mainMod}, t, togglespecialworkspace"

                  "${mainMod} ${SECONDARY} ${TERTIARY}, Q, exit"
                  "${mainMod}, Q, killactive"
                  "${mainMod}, F, togglefloating"
                  "${mainMod}, G, fullscreen"
                  "${mainMod}, P, layoutmsg, togglesplit"

                  "${mainMod}, k, movefocus, u"
                  "${mainMod}, j, movefocus, d"
                  "${mainMod}, l, movefocus, r"
                  "${mainMod}, h, movefocus, l"

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

                  ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                  ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                  ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"

                  ", XF86AudioPlay, exec, playerctl play-pause"
                  ", XF86AudioNext, exec, playerctl next"
                  ", XF86AudioPrev, exec, playerctl previous"

                  ", XF86MonBrightnessUp,   exec, brightnessctl set +10%"
                  ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
                ];

                binde = [
                  "${mainMod} ${TERTIARY}, k, resizeactive, 0 -20"
                  "${mainMod} ${TERTIARY}, j, resizeactive, 0 20"
                  "${mainMod} ${TERTIARY}, l, resizeactive, 20 0"
                  "${mainMod} ${TERTIARY}, h, resizeactive, -20 0"
                  "${mainMod} ALT,  k, swapwindow, u"
                  "${mainMod} ALT,  j, swapwindow, d"
                  "${mainMod} ALT,  l, swapwindow, r"
                  "${mainMod} ALT,  h, swapwindow, l"
                ];

                bindm = [
                  "${mainMod}, mouse:272, movewindow"
                  "${mainMod}, mouse:273, resizewindow"
                ];

                # === Rules ===
                windowrule = [
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

                  "opacity 0.91 override 0.73 override, match:class ^(Emacs)$"

                  "workspace 1, match:class ^(code|Code)$"
                  "workspace 2, match:class ^(Alacritty|alacritty)$"
                  "workspace 3, match:class ^(zen|ZenBrowser)$"
                  "workspace 4, match:class ^(Slack)$"
                  "workspace 4, match:class ^(discord)$"
                  "workspace 5, match:class ^(spotify)$"
                  "workspace 6, match:class ^(btop|htop|nvtop|MissionCenter)$"
                ];
              };
          };

          fish.loginShellInit = ''
            if test (tty) = "/dev/tty1"
              exec Hyprland &> /dev/null
            end
          '';
        };

        xdg.portal = {
          enable = true;
          xdgOpenUsePortal = true;
          config = {
            common.default = [ "gtk" ];
            hyprland.default = [
              "gtk"
              "hyprland"
            ];
          };
          extraPortals = [
            pkgs.xdg-desktop-portal-gtk
          ];
        };
      };
    };
}
