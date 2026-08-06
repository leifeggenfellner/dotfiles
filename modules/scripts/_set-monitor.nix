{ pkgs, ... }:

pkgs.writeShellScriptBin "set-monitor" ''
  case "$1" in
    on)
      hyprctl eval 'hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1 })'
      ;;
    off)
      hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
      ;;
    *)
      echo "Usage: set-monitor [on|off]"
      ;;
  esac
''
