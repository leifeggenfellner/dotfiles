{ pkgs }:
pkgs.runCommand "monitor-control-check"
{
  nativeBuildInputs = [ pkgs.lua pkgs.python3 ];
  MONITOR_CONTROL_SOURCE = ./_monitor-control.py;
}
  ''
    python3 ${./_monitor-control_test.py}
    ! grep -F '"keyword"' ${./_monitor-control.py}
    grep -F 'hl.monitor(' ${./_monitor-control.py}
    grep -F 'def workspace_rule_command(' ${./_monitor-control.py}
    grep -F 'def window_rule_command(' ${./_monitor-control.py}
    ! grep -F 'set-monitor' ${./default.nix}
    touch $out
  ''
