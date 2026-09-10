{ lib, quickshell, riceEnabled }:
let
  lua = lib.generators.mkLuaInline;
  main = "SUPER";
  shift = "SHIFT";
  ctrl = "CTRL";
  mainShift = "${main} + ${shift}";
  mainCtrl = "${main} + ${ctrl}";
  mainAlt = "${main} + ALT";
  mainShiftCtrl = "${main} + ${shift} + ${ctrl}";

  key = modifiers: keyName: if modifiers == "" then keyName else "${modifiers} + ${keyName}";
  launch = program: "uwsm app -- ${program}";
  toggle = program: "pkill ${builtins.substring 0 14 program} || ${launch program}";
  runOnce = program: "pgrep ${program} || ${launch program}";
  riceIpc = target: action: "${quickshell} -c rice ipc call ${target} ${action}";
  riceOsd = action: fallback:
    "sh -c ${lib.escapeShellArg "${riceIpc "osd" action} >/dev/null 2>&1 || ${fallback}"}";

  mkBind = keys: dispatcher: { _args = [ keys (lua dispatcher) ]; };
  mkBindWith = keys: dispatcher: flags: { _args = [ keys (lua dispatcher) flags ]; };
  exec = command: "hl.dsp.exec_cmd(${builtins.toJSON command})";
  workspace = value: "hl.dsp.focus({ workspace = ${builtins.toJSON value} })";
  moveWorkspace = value: "hl.dsp.window.move({ workspace = ${builtins.toJSON value} })";

  workspaceBindings = lib.concatMap
    (number: [
      (mkBind (key main (toString number)) (workspace number))
      (mkBind (key mainShift (toString number)) (moveWorkspace number))
    ])
    (lib.range 1 9);

  mediaBindings =
    if riceEnabled then [
      (mkBind "XF86AudioRaiseVolume" (exec (riceOsd "volumeUp" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+")))
      (mkBind "XF86AudioLowerVolume" (exec (riceOsd "volumeDown" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")))
      (mkBind "XF86AudioMute" (exec (riceOsd "toggleMute" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")))
      (mkBind "XF86MonBrightnessUp" (exec (riceOsd "brightnessUp" "brightnessctl set +10%")))
      (mkBind "XF86MonBrightnessDown" (exec (riceOsd "brightnessDown" "brightnessctl set 10%-")))
    ] else [
      (mkBind "XF86AudioRaiseVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
      (mkBind "XF86AudioLowerVolume" (exec "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
      (mkBind "XF86AudioMute" (exec "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
      (mkBind "XF86MonBrightnessUp" (exec "brightnessctl set +10%"))
      (mkBind "XF86MonBrightnessDown" (exec "brightnessctl set 10%-"))
    ];

  shellBindings =
    if riceEnabled then [
      (mkBind (key main "Space") (exec (riceIpc "shell" "toggleLauncher")))
      (mkBind (key main "D") (exec (riceIpc "shell" "toggleDashboard")))
      (mkBind (key mainAlt "T") (exec (riceIpc "shell" "toggleSwitcher")))
      (mkBind (key mainShift "W") (exec (riceIpc "shell" "toggleSwitcher")))
      (mkBind (key main "W") (exec (riceIpc "shell" "toggleWallpapers")))
      (mkBind (key mainAlt "W") (exec (riceIpc "wallpapers" "next")))
      (mkBind (key main "V") (exec (riceIpc "shell" "toggleSatchel")))
      (mkBind (key main "N") (exec (riceIpc "notifications" "toggleCenter")))
      (mkBind (key mainShiftCtrl "N") (exec (riceIpc "notifications" "clearAll")))
    ] else [
      (mkBind (key main "W") (exec (launch "foot -T wallpaper-picker -e wallpaper-picker")))
      (mkBind (key main "N") (exec "swaync-client -t -sw"))
      (mkBind (key mainShift "N") (exec "swaync-client -d -sw"))
      (mkBind (key mainShiftCtrl "N") (exec "swaync-client -C -sw"))
    ];
in
{
  bind = [
    (mkBind (key main "Return") (exec (launch "foot")))
    (mkBind (key main "B") (exec (toggle "foot -T btop -e btop")))
    (mkBind (key main "R") (exec (toggle "foot -T yazi -e yazi")))
    (mkBind (key main "S") (exec (launch "spotify")))
    (mkBind (key mainShift "D") (exec (runOnce "pcmanfm")))
    (mkBind (key mainShift "L") (exec "lock-screen"))
    (mkBind (key mainShift "P") (exec (runOnce "grimblast --notify copy area")))
    (mkBind (key mainShift "T") (moveWorkspace "special"))
    (mkBind (key main "t") "hl.dsp.workspace.toggle_special(\"\")")
    (mkBind (key mainShiftCtrl "Q") (exec "uwsm stop"))
    (mkBind (key main "Q") "hl.dsp.window.close()")
    (mkBind (key main "F") "hl.dsp.window.float({ action = \"toggle\" })")
    (mkBind (key main "G") "hl.dsp.window.fullscreen({ action = \"toggle\" })")
    (mkBind (key main "P") "hl.dsp.layout(\"togglesplit\")")
    (mkBind (key main "k") "hl.dsp.focus({ direction = \"u\" })")
    (mkBind (key main "j") "hl.dsp.focus({ direction = \"d\" })")
    (mkBind (key main "l") "hl.dsp.focus({ direction = \"r\" })")
    (mkBind (key main "h") "hl.dsp.focus({ direction = \"l\" })")
    (mkBind (key main "left") (workspace "e-1"))
    (mkBind (key main "right") (workspace "e+1"))
    (mkBind (key mainShift "right") (moveWorkspace "e+1"))
    (mkBind (key mainShift "left") (moveWorkspace "e-1"))
    (mkBind "XF86AudioPlay" (exec "playerctl play-pause"))
    (mkBind "XF86AudioNext" (exec "playerctl next"))
    (mkBind "XF86AudioPrev" (exec "playerctl previous"))
  ] ++ workspaceBindings ++ mediaBindings ++ shellBindings ++ [
    (mkBindWith (key mainCtrl "k") "hl.dsp.window.resize({ x = 0, y = -20, relative = true })" { repeating = true; })
    (mkBindWith (key mainCtrl "j") "hl.dsp.window.resize({ x = 0, y = 20, relative = true })" { repeating = true; })
    (mkBindWith (key mainCtrl "l") "hl.dsp.window.resize({ x = 20, y = 0, relative = true })" { repeating = true; })
    (mkBindWith (key mainCtrl "h") "hl.dsp.window.resize({ x = -20, y = 0, relative = true })" { repeating = true; })
    (mkBindWith (key mainAlt "k") "hl.dsp.window.swap({ direction = \"u\" })" { repeating = true; })
    (mkBindWith (key mainAlt "j") "hl.dsp.window.swap({ direction = \"d\" })" { repeating = true; })
    (mkBindWith (key mainAlt "l") "hl.dsp.window.swap({ direction = \"r\" })" { repeating = true; })
    (mkBindWith (key mainAlt "h") "hl.dsp.window.swap({ direction = \"l\" })" { repeating = true; })
    (mkBindWith (key main "mouse:272") "hl.dsp.window.drag()" { mouse = true; })
    (mkBindWith (key main "mouse:273") "hl.dsp.window.resize()" { mouse = true; })
  ];
}
