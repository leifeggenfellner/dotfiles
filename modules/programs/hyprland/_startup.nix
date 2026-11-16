{ lib, monitorControlEnabled, riceEnabled, style }:
let
  restoreWallpaper = "wallpaper-restore";
  applyRiceTheme = "rice-hyprland-theme --active";
  finalizeSession = "uwsm finalize" + lib.optionalString monitorControlEnabled " && systemctl --user start --no-block monitor-control.service";
  quickshellRice = "pgrep -f '[q]uickshell.*rice' || uwsm app -- rice-shell --prod";
  execOnce = (if riceEnabled then [ applyRiceTheme ] else [ ]) ++ [
    "hyprctl setcursor ${style.cursorName} ${toString style.cursorSize}"
    "wl-clip-persist --clipboard both"
    "wl-paste --watch cliphist store"
    finalizeSession
    restoreWallpaper
  ] ++ (if riceEnabled then [ quickshellRice ] else [ ]);
  startFunction = ''
    function()
    ${lib.concatMapStringsSep "\n" (command: "  hl.exec_cmd(${builtins.toJSON command})") execOnce}
    end
  '';
in
{
  on = [
    {
      _args = [
        "hyprland.start"
        (lib.generators.mkLuaInline startFunction)
      ];
    }
  ]
  # A reload (every rebuild) re-runs the config and drops the live theme's
  # colours and animations (D-047); put them back.
  ++ lib.optional riceEnabled {
    _args = [
      "config.reloaded"
      (lib.generators.mkLuaInline ''
        function()
          hl.exec_cmd(${builtins.toJSON applyRiceTheme})
        end
      '')
    ];
  };
}
