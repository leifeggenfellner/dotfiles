{ inputs, ... }:
{
  flake.nixosModules.services-hyprland =
    { lib, pkgs, config, ... }:
    let
      themeLib = import ../rice/nix/_themes-lib.nix { inherit lib; };
      c = import ../themes/_palette.nix {
        scheme = config.environment.desktop.theme.scheme;
        themePackages = if (config.rice.enable or false) then themeLib.themePackages config.rice else { };
      };
      fmt = import ../themes/_fmt.nix lib;
      s = config.environment.desktop.theme.style;
      accent1 = c.${s.accentPrimary};
      accent2 = c.${s.accentSecondary};
      accent3 = c.${s.accentTertiary};
    in
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
            plugins = [ ];

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
                riceOsd = action: fallback: "sh -c '${pkgs.quickshell}/bin/quickshell -c rice ipc call osd ${action} >/dev/null 2>&1 || ${fallback}'";
              in
              {
                # === Settings ===
                env = [
                  "GRIMBLAST_NO_CURSOR,0"
                  "HYPRCURSOR_THEME,${pkgs.capitaine-cursors}"
                  "HYPRCURSOR_SIZE,${toString s.cursorSize}"
                  "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
                ];
                exec-once = [
                  "wallpaper-restore"
                  "hyprctl setcursor ${s.cursorName} ${toString s.cursorSize}"
                  "wl-clip-persist --clipboard both &"
                  "wl-paste --watch cliphist store &"
                  "uwsm finalize"
                  "thunderbolt-wait && setup-monitors"
                  "handle-monitor &"
                ] ++ lib.optionals config.rice.enable [
                  "uwsm app -- rice-shell"
                ];

                general = {
                  gaps_in = s.gapsInner;
                  gaps_out = s.gapsOuter;
                  border_size = s.borderWidth;
                  allow_tearing = true;
                  resize_on_border = true;
                  "col.active_border" = "${fmt.rgb accent1} ${fmt.rgb accent2} ${fmt.rgb accent3} 45deg";
                  "col.inactive_border" = fmt.rgb c.surface0;
                  hover_icon_on_border = true;
                  extend_border_grab_area = 15;
                };

                cursor = {
                  inactive_timeout = 3;
                  no_hardware_cursors = false;
                  enable_hyprcursor = true;
                };

                decoration = {
                  inherit (s) rounding;

                  blur = {
                    enabled = true;
                    size = s.blurSize;
                    passes = s.blurPasses;
                    new_optimizations = true;
                    ignore_opacity = true;
                    xray = false;
                    contrast = s.blurContrast;
                    brightness = s.blurBrightness;
                    noise = s.blurNoise;
                  };

                  active_opacity = s.opacityActive;
                  inactive_opacity = s.opacityInactive;
                  fullscreen_opacity = 1.0;
                };

                layerrule = [
                  "blur on, match:namespace ^(wofi)$"
                  "ignore_alpha 0, match:namespace ^(wofi)$"
                  "blur on, match:namespace ^(waybar)$"
                  "ignore_alpha 0, match:namespace ^(waybar)$"
                  "blur on, match:namespace ^(swaync-notification-window)$"
                  "ignore_alpha 0, match:namespace ^(swaync-notification-window)$"
                  "blur on, match:namespace ^(swaync-control-center)$"
                  "ignore_alpha 0, match:namespace ^(swaync-control-center)$"
                ];

                animations.enabled = true;

                bezier = [
                  "wind, ${s.bezierWind}"
                  "winIn, ${s.bezierWinIn}"
                  "winOut, ${s.bezierWinOut}"
                  "liner, ${s.bezierLiner}"
                  "overshot, ${s.bezierOvershot}"
                ];

                animation = [
                  "windows, 1, ${toString s.speedWindowOpen}, wind, slide"
                  "windowsIn, 1, ${toString s.speedWindowOpen}, winIn, slide"
                  "windowsOut, 1, ${toString s.speedWindowClose}, winOut, slide"
                  "windowsMove, 1, ${toString s.speedWindowMove}, wind, slide"
                  "border, 1, ${toString s.speedBorder}, liner"
                  "borderangle, 1, ${toString s.speedBorderAngle}, liner, loop"
                  "fade, 1, ${toString s.speedFade}, default"
                  "layers, 1, ${toString s.speedLayer}, wind, slide"
                  "layersIn, 1, ${toString s.speedLayerIn}, winIn, slide"
                  "layersOut, 1, ${toString s.speedLayerOut}, winOut, fade"
                  "workspaces, 1, ${toString s.speedWorkspace}, overshot, slidevert"
                  "specialWorkspace, 1, ${toString s.speedSpecialWorkspace}, default, slidevert"
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
                    font_size = s.fontSizeSmall;
                    gradients = true;
                    render_titles = true;
                    scrolling = true;
                  };
                  "col.border_active" = fmt.rgb accent1;
                  "col.border_inactive" = fmt.rgb c.surface0;
                };

                dwindle = {
                  # pseudotile option removed in Hyprland 0.55; the `pseudo`
                  # dispatcher is now always available.
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
                  "${mainMod}, Return, exec, ${launch "foot"}"
                  "${mainMod}, B, exec, ${toggle "foot -T btop -e btop"}"
                  "${mainMod}, R, exec, ${toggle "foot -T yazi -e yazi"}"
                  "${mainMod}, S, exec, ${launch "spotify"}"
                  "${mainMod} ${SECONDARY}, D, exec, ${runOnce "pcmanfm"}"
                  "${mainMod} ${SECONDARY}, W, exec, ${launch "foot -T theme-switcher -e theme-switcher"}"

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

                  ", XF86AudioPlay, exec, playerctl play-pause"
                  ", XF86AudioNext, exec, playerctl next"
                  ", XF86AudioPrev, exec, playerctl previous"
                ] ++ (if config.rice.enable then [
                  ", XF86AudioRaiseVolume, exec, ${riceOsd "volumeUp" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"}"
                  ", XF86AudioLowerVolume, exec, ${riceOsd "volumeDown" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"}"
                  ", XF86AudioMute,        exec, ${riceOsd "toggleMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"}"
                  ", XF86MonBrightnessUp,   exec, ${riceOsd "brightnessUp" "brightnessctl set +10%"}"
                  ", XF86MonBrightnessDown, exec, ${riceOsd "brightnessDown" "brightnessctl set 10%-"}"

                  # Rice shell surfaces (see docs/architecture/ROADMAP.md)
                  "${mainMod}, D, exec, quickshell -c rice ipc call shell toggleLauncher"
                  "${mainMod} ALT, T, exec, quickshell -c rice ipc call shell toggleSwitcher"
                  "${mainMod}, W, exec, quickshell -c rice ipc call shell toggleWallpapers"
                  "${mainMod} ALT, W, exec, quickshell -c rice ipc call wallpapers next"
                  "${mainMod}, V, exec, quickshell -c rice ipc call shell toggleSatchel"
                  "${mainMod}, N, exec, quickshell -c rice ipc call notifications toggleCenter"
                  "${mainMod} ${SECONDARY} ${TERTIARY}, N, exec, quickshell -c rice ipc call notifications clearAll"
                ] else [
                  ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
                  ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
                  ", XF86AudioMute,        exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
                  ", XF86MonBrightnessUp,   exec, brightnessctl set +10%"
                  ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"

                  # Non-rice hosts keep the fzf wallpaper picker on Super+W.
                  "${mainMod}, W, exec, ${launch "foot -T wallpaper-picker -e wallpaper-picker"}"
                  "${mainMod}, N, exec, swaync-client -t -sw"
                  "${mainMod} ${SECONDARY}, N, exec, swaync-client -d -sw"
                  "${mainMod} ${SECONDARY} ${TERTIARY}, N, exec, swaync-client -C -sw"
                ]);

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
                  "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(yazi)$"
                  "float on, size (monitor_w*0.5) (monitor_h*0.7), center on, match:title ^(btop)$"
                  "float on, size (monitor_w*0.4) (monitor_h*0.7), center on, match:title ^(theme-switcher)$"
                  "float on, size (monitor_w*0.6) (monitor_h*0.8), center on, match:title ^(wallpaper-picker)$"

                  "workspace 1, match:class ^(code|Code)$"
                  "workspace 2, match:class ^(Alacritty|alacritty|foot)$"
                  "workspace 3, match:class ^(zen|ZenBrowser)$"
                  "workspace 4, match:class ^(Slack)$"
                  "workspace 4, match:class ^(discord)$"
                  "workspace 5, match:class ^(spotify)$"
                  "workspace 6, match:class ^(btop|htop|nvtop|MissionCenter)$"
                  "opacity 1.0 override 1.0 override, match:class ^(zen|ZenBrowser)$"
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
