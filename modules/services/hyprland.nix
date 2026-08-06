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

      q = builtins.toJSON;
      lines = lib.concatStringsSep "\n";
      mods = lib.concatStringsSep " + ";
      key = modifiers: keyName: if modifiers == "" then keyName else "${modifiers} + ${keyName}";
      luaBool = value: if value then "true" else "false";
      luaValue = value:
        if builtins.isBool value then luaBool value
        else if builtins.isInt value || builtins.isFloat value then toString value
        else if builtins.isString value then q value
        else throw "Unsupported Lua value in Hyprland config";
      luaAttrs = attrs:
        "{ ${lib.concatStringsSep ", " (lib.mapAttrsToList (name: value: "${name} = ${luaValue value}") attrs)} }";
      flagsArg = flags: if flags == { } then "" else ", ${luaAttrs flags}";
      bind = keys: dispatcher: ''hl.bind(${q keys}, ${dispatcher})'';
      bindWith = keys: dispatcher: flags: ''hl.bind(${q keys}, ${dispatcher}${flagsArg flags})'';
      bindExec = keys: command: bind keys ''hl.dsp.exec_cmd(${q command})'';
      bezierCurve = name: value:
        let
          points = lib.splitString "," value;
        in
        ''hl.curve(${q name}, { type = "bezier", points = { {${lib.elemAt points 0}, ${lib.elemAt points 1}}, {${lib.elemAt points 2}, ${lib.elemAt points 3}} } })'';
      animation = { leaf, speed, bezier, style ? null }:
        ''hl.animation({ leaf = ${q leaf}, enabled = true, speed = ${toString speed}, bezier = ${q bezier}${lib.optionalString (style != null) ", style = ${q style}"} })'';

      mainMod = "SUPER";
      SECONDARY = "SHIFT";
      TERTIARY = "CTRL";
      mainShift = mods [ mainMod SECONDARY ];
      mainCtrl = mods [ mainMod TERTIARY ];
      mainAlt = mods [ mainMod "ALT" ];
      mainShiftCtrl = mods [ mainMod SECONDARY TERTIARY ];

      toggle =
        program:
        let
          prog = builtins.substring 0 14 program;
        in
        "pkill ${prog} || uwsm app -- ${program}";

      runOnce = program: "pgrep ${program} || uwsm app -- ${program}";
      launch = program: "uwsm app -- ${program}";
      riceOsd = action: fallback: "sh -c '${pkgs.quickshell}/bin/quickshell -c rice ipc call osd ${action} >/dev/null 2>&1 || ${fallback}'";

      env = [
        [ "GRIMBLAST_NO_CURSOR" "0" ]
        [ "HYPRCURSOR_THEME" "${pkgs.capitaine-cursors}" ]
        [ "HYPRCURSOR_SIZE" (toString s.cursorSize) ]
        [ "QT_WAYLAND_DISABLE_WINDOWDECORATION" "1" ]
      ];

      execOnce = [
        "wallpaper-restore"
        "hyprctl setcursor ${s.cursorName} ${toString s.cursorSize}"
        "wl-clip-persist --clipboard both"
        "wl-paste --watch cliphist store"
        "uwsm finalize"
        "thunderbolt-wait && setup-monitors"
        "handle-monitor"
      ] ++ lib.optionals config.rice.enable [
        "uwsm app -- rice-shell"
      ];

      workspaceBinds = lib.flatten (builtins.genList
        (i:
          let
            ws = i + 1;
          in
          [
            (bind (key mainMod (toString ws)) ''hl.dsp.focus({ workspace = ${toString ws} })'')
            (bind (key mainShift (toString ws)) ''hl.dsp.window.move({ workspace = ${toString ws} })'')
          ]) 9);

      commonBinds = [
        (bindExec (key mainMod "Return") (launch "foot"))
        (bindExec (key mainMod "B") (toggle "foot -T btop -e btop"))
        (bindExec (key mainMod "R") (toggle "foot -T yazi -e yazi"))
        (bindExec (key mainMod "S") (launch "spotify"))
        (bindExec (key mainShift "D") (runOnce "pcmanfm"))
        (bindExec (key mainShift "W") (launch "foot -T theme-switcher -e theme-switcher"))
        (bindExec (key mainShift "L") "lock-screen")
        (bindExec (key mainShift "P") (runOnce "grimblast --notify copy area"))
        (bind (key mainShift "T") ''hl.dsp.window.move({ workspace = "special" })'')
        (bind (key mainMod "t") ''hl.dsp.workspace.toggle_special("")'')
        (bindExec (key mainShiftCtrl "Q") "uwsm stop")
        (bind (key mainMod "Q") ''hl.dsp.window.close()'')
        (bind (key mainMod "F") ''hl.dsp.window.float({ action = "toggle" })'')
        (bind (key mainMod "G") ''hl.dsp.window.fullscreen({ action = "toggle" })'')
        (bind (key mainMod "P") ''hl.dsp.layout("togglesplit")'')
        (bind (key mainMod "k") ''hl.dsp.focus({ direction = "u" })'')
        (bind (key mainMod "j") ''hl.dsp.focus({ direction = "d" })'')
        (bind (key mainMod "l") ''hl.dsp.focus({ direction = "r" })'')
        (bind (key mainMod "h") ''hl.dsp.focus({ direction = "l" })'')
        (bind (key mainMod "left") ''hl.dsp.focus({ workspace = "e-1" })'')
        (bind (key mainMod "right") ''hl.dsp.focus({ workspace = "e+1" })'')
        (bind (key mainShift "right") ''hl.dsp.window.move({ workspace = "e+1" })'')
        (bind (key mainShift "left") ''hl.dsp.window.move({ workspace = "e-1" })'')
        (bindExec "XF86AudioPlay" "playerctl play-pause")
        (bindExec "XF86AudioNext" "playerctl next")
        (bindExec "XF86AudioPrev" "playerctl previous")
      ] ++ workspaceBinds;

      riceBinds = [
        (bindExec "XF86AudioRaiseVolume" (riceOsd "volumeUp" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
        (bindExec "XF86AudioLowerVolume" (riceOsd "volumeDown" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
        (bindExec "XF86AudioMute" (riceOsd "toggleMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
        (bindExec "XF86MonBrightnessUp" (riceOsd "brightnessUp" "brightnessctl set +10%"))
        (bindExec "XF86MonBrightnessDown" (riceOsd "brightnessDown" "brightnessctl set 10%-"))
        (bindExec (key mainMod "Space") "quickshell -c rice ipc call shell toggleLauncher")
        (bindExec (key mainMod "D") "quickshell -c rice ipc call shell toggleDashboard")
        (bindExec (key mainAlt "T") "quickshell -c rice ipc call shell toggleSwitcher")
        (bindExec (key mainMod "W") "quickshell -c rice ipc call shell toggleWallpapers")
        (bindExec (key mainAlt "W") "quickshell -c rice ipc call wallpapers next")
        (bindExec (key mainMod "V") "quickshell -c rice ipc call shell toggleSatchel")
        (bindExec (key mainMod "N") "quickshell -c rice ipc call notifications toggleCenter")
        (bindExec (key mainShiftCtrl "N") "quickshell -c rice ipc call notifications clearAll")
      ];

      fallbackBinds = [
        (bindExec "XF86AudioRaiseVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")
        (bindExec "XF86AudioLowerVolume" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
        (bindExec "XF86AudioMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
        (bindExec "XF86MonBrightnessUp" "brightnessctl set +10%")
        (bindExec "XF86MonBrightnessDown" "brightnessctl set 10%-")
        (bindExec (key mainMod "W") (launch "foot -T wallpaper-picker -e wallpaper-picker"))
        (bindExec (key mainMod "N") "swaync-client -t -sw")
        (bindExec (key mainShift "N") "swaync-client -d -sw")
        (bindExec (key mainShiftCtrl "N") "swaync-client -C -sw")
      ];

      repeatingBinds = [
        (bindWith (key mainCtrl "k") ''hl.dsp.window.resize({ x = 0, y = -20, relative = true })'' { repeating = true; })
        (bindWith (key mainCtrl "j") ''hl.dsp.window.resize({ x = 0, y = 20, relative = true })'' { repeating = true; })
        (bindWith (key mainCtrl "l") ''hl.dsp.window.resize({ x = 20, y = 0, relative = true })'' { repeating = true; })
        (bindWith (key mainCtrl "h") ''hl.dsp.window.resize({ x = -20, y = 0, relative = true })'' { repeating = true; })
        (bindWith (key mainAlt "k") ''hl.dsp.window.swap({ direction = "u" })'' { repeating = true; })
        (bindWith (key mainAlt "j") ''hl.dsp.window.swap({ direction = "d" })'' { repeating = true; })
        (bindWith (key mainAlt "l") ''hl.dsp.window.swap({ direction = "r" })'' { repeating = true; })
        (bindWith (key mainAlt "h") ''hl.dsp.window.swap({ direction = "l" })'' { repeating = true; })
      ];

      mouseBinds = [
        (bindWith (key mainMod "mouse:272") ''hl.dsp.window.drag()'' { mouse = true; })
        (bindWith (key mainMod "mouse:273") ''hl.dsp.window.resize()'' { mouse = true; })
      ];

      floatingClassRules = [
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

      floatingTitleRules = [
        "^(Spotify Premium)$"
        "^(Spotify)$"
        "^(spotify_player)$"
        "^(yazi)$"
        "^(btop)$"
      ];

      workspaceRules = [
        [ "class" "^(code|Code)$" "1" ]
        [ "class" "^(Alacritty|alacritty|foot)$" "2" ]
        [ "class" "^(zen|ZenBrowser)$" "3" ]
        [ "class" "^(Slack)$" "4" ]
        [ "class" "^(discord)$" "4" ]
        [ "class" "^(spotify)$" "5" ]
        [ "class" "^(btop|htop|nvtop|MissionCenter)$" "6" ]
      ];

      luaConfig = ''
        hl.config({
            general = {
                gaps_in = ${toString s.gapsInner},
                gaps_out = ${toString s.gapsOuter},
                border_size = ${toString s.borderWidth},
                allow_tearing = true,
                resize_on_border = true,
                col = {
                    active_border = ${q "${fmt.rgb accent1} ${fmt.rgb accent2} ${fmt.rgb accent3} 45deg"},
                    inactive_border = ${q (fmt.rgb c.surface0)},
                },
                hover_icon_on_border = true,
                extend_border_grab_area = 15,
            },

            cursor = {
                inactive_timeout = 3,
                no_hardware_cursors = 0,
                enable_hyprcursor = true,
            },

            decoration = {
                rounding = ${toString s.rounding},
                blur = {
                    enabled = true,
                    size = ${toString s.blurSize},
                    passes = ${toString s.blurPasses},
                    new_optimizations = true,
                    ignore_opacity = true,
                    xray = false,
                    contrast = ${toString s.blurContrast},
                    brightness = ${toString s.blurBrightness},
                    noise = ${toString s.blurNoise},
                },
                active_opacity = ${toString s.opacityActive},
                inactive_opacity = ${toString s.opacityInactive},
                fullscreen_opacity = 1.0,
            },

            animations = {
                enabled = true,
            },

            input = {
                kb_layout = "no",
                follow_mouse = 1,
                mouse_refocus = true,
                sensitivity = 0.0,
                accel_profile = "adaptive",
                touchpad = {
                    natural_scroll = true,
                    disable_while_typing = true,
                    tap_to_click = true,
                    middle_button_emulation = true,
                },
            },

            group = {
                groupbar = {
                    font_size = ${toString s.fontSizeSmall},
                    gradients = true,
                    render_titles = true,
                    scrolling = true,
                },
                col = {
                    border_active = ${q (fmt.rgb accent1)},
                    border_inactive = ${q (fmt.rgb c.surface0)},
                },
            },

            dwindle = {
                preserve_split = true,
                force_split = 1,
                default_split_ratio = 1.2,
                smart_split = false,
                smart_resizing = false,
                use_active_for_splits = true,
            },

            misc = {
                disable_autoreload = true,
                force_default_wallpaper = 0,
                animate_mouse_windowdragging = true,
                animate_manual_resizes = true,
                vrr = 1,
                focus_on_activate = true,
                mouse_move_focuses_monitor = true,
                enable_swallow = true,
                swallow_regex = "^(foot|alacritty|kitty)$",
            },

            xwayland = {
                force_zero_scaling = true,
            },

            debug = {
                disable_logs = false,
            },
        })

        ${lines (map (entry: ''hl.env(${q (lib.elemAt entry 0)}, ${q (lib.elemAt entry 1)})'') env)}

        hl.on("hyprland.start", function()
        ${lines (map (command: ''    hl.exec_cmd(${q command})'') execOnce)}
        end)

        ${bezierCurve "wind" s.bezierWind}
        ${bezierCurve "winIn" s.bezierWinIn}
        ${bezierCurve "winOut" s.bezierWinOut}
        ${bezierCurve "liner" s.bezierLiner}
        ${bezierCurve "overshot" s.bezierOvershot}

        ${animation { leaf = "windows"; speed = s.speedWindowOpen; bezier = "wind"; style = "slide"; }}
        ${animation { leaf = "windowsIn"; speed = s.speedWindowOpen; bezier = "winIn"; style = "slide"; }}
        ${animation { leaf = "windowsOut"; speed = s.speedWindowClose; bezier = "winOut"; style = "slide"; }}
        ${animation { leaf = "windowsMove"; speed = s.speedWindowMove; bezier = "wind"; style = "slide"; }}
        ${animation { leaf = "border"; speed = s.speedBorder; bezier = "liner"; }}
        ${animation { leaf = "borderangle"; speed = s.speedBorderAngle; bezier = "liner"; style = "loop"; }}
        ${animation { leaf = "fade"; speed = s.speedFade; bezier = "default"; }}
        ${animation { leaf = "layers"; speed = s.speedLayer; bezier = "wind"; style = "slide"; }}
        ${animation { leaf = "layersIn"; speed = s.speedLayerIn; bezier = "winIn"; style = "slide"; }}
        ${animation { leaf = "layersOut"; speed = s.speedLayerOut; bezier = "winOut"; style = "fade"; }}
        ${animation { leaf = "workspaces"; speed = s.speedWorkspace; bezier = "overshot"; style = "slidevert"; }}
        ${animation { leaf = "specialWorkspace"; speed = s.speedSpecialWorkspace; bezier = "default"; style = "slidevert"; }}

        hl.workspace_rule({ workspace = "special:magic", gaps_in = 20, gaps_out = 40 })

        local function blurred_layer(namespace)
            hl.layer_rule({
                match = { namespace = namespace },
                blur = true,
                ignore_alpha = 0,
            })
        end

        blurred_layer("^(wofi)$")
        blurred_layer("^(waybar)$")
        blurred_layer("^(swaync-notification-window)$")
        blurred_layer("^(swaync-control-center)$")

        ${lines commonBinds}
        ${lines (if config.rice.enable then riceBinds else fallbackBinds)}
        ${lines repeatingBinds}
        ${lines mouseBinds}

        local function floating_class(pattern, width, height)
            hl.window_rule({
                match = { class = pattern },
                float = true,
                size = { width, height },
                center = true,
            })
        end

        local function floating_title(pattern, width, height)
            hl.window_rule({
                match = { title = pattern },
                float = true,
                size = { width, height },
                center = true,
            })
        end

        ${lines (map (pattern: ''floating_class(${q pattern}, "monitor_w*0.5", "monitor_h*0.7")'') floatingClassRules)}
        ${lines (map (pattern: ''floating_title(${q pattern}, "monitor_w*0.5", "monitor_h*0.7")'') floatingTitleRules)}
        floating_title("^(theme-switcher)$", "monitor_w*0.4", "monitor_h*0.7")
        floating_title("^(wallpaper-picker)$", "monitor_w*0.6", "monitor_h*0.8")

        ${lines (map (rule:
          let
            matchKind = lib.elemAt rule 0;
            pattern = lib.elemAt rule 1;
            workspace = lib.elemAt rule 2;
          in
          ''hl.window_rule({ match = { ${matchKind} = ${q pattern} }, workspace = ${q workspace} })'') workspaceRules)}
        hl.window_rule({ match = { class = "^(zen|ZenBrowser)$" }, opacity = "1.0 override 1.0 override" })
      '';
    in
    {
      imports = [
        inputs.hyprland.nixosModules.default
      ];

      config = lib.mkIf (config.environment.desktop.windowManager == "hyprland") {
        environment = {
          etc."xdg/hypr/hyprland.lua".text = luaConfig;
          systemPackages = [
            inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
          ];
          pathsToLink = [ "/share/icons" ];
          variables = {
            HYPRLAND_CONFIG = "/etc/xdg/hypr/hyprland.lua";
            NIXOS_OZONE_WL = "1";
          };
        };

        programs = {
          hyprland = {
            enable = true;
            withUWSM = true;
            package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
            portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
            plugins = [ ];
          };

          fish.loginShellInit = ''
            if test (tty) = "/dev/tty1"
              exec Hyprland --config /etc/xdg/hypr/hyprland.lua &> /dev/null
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
