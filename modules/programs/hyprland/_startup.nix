{ lib, riceEnabled, style }:
let
  setupDisplays = "setup-monitors";
  restoreWallpaper = "wallpaper-restore";
  applyRiceTheme = "rice-hyprland-theme --active";
  monitorHandler = "pgrep -f '[h]andle-monitor' || uwsm app -- handle-monitor";
  quickshellRice = "pgrep -f '[q]uickshell.*rice' || uwsm app -- rice-shell --prod";
  execOnce = (if riceEnabled then [ applyRiceTheme ] else [ ]) ++ [
    setupDisplays
    restoreWallpaper
    "hyprctl setcursor ${style.cursorName} ${toString style.cursorSize}"
    "wl-clip-persist --clipboard both"
    "wl-paste --watch cliphist store"
    "uwsm finalize"
    "thunderbolt-wait && ${setupDisplays} && ${restoreWallpaper}"
    monitorHandler
  ] ++ (if riceEnabled then [ quickshellRice ] else [ ]);
  startFunction = ''
    function()
    ${lib.concatMapStringsSep "\n" (command: "  hl.exec_cmd(${builtins.toJSON command})") execOnce}
    end
  '';
in
{
  on._args = [
    "hyprland.start"
    (lib.generators.mkLuaInline startFunction)
  ];
}
