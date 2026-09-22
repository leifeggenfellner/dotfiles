{ pkgs, hyprland, monitors, monitorControl }:
let
  configFile = pkgs.writeText "monitor-control.json" (builtins.toJSON {
    schemaVersion = 1;
    inherit monitors;
    inherit (monitorControl) profiles fallbackProfile appRoutes;
  });
in
pkgs.writeShellApplication {
  name = "monitor-control";
  runtimeInputs = [ hyprland ];
  text = ''
    exec ${pkgs.python3}/bin/python3 ${./_monitor-control.py} --config ${configFile} "$@"
  '';
}
