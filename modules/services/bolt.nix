_: {
  flake.nixosModules.services-bolt =
    { pkgs, ... }:
    {
      services.hardware.bolt.enable = true;

      systemd.services.thunderbolt-retrigger = {
        description = "Re-trigger Thunderbolt DP tunnels";
        after = [ "bolt.service" "graphical.target" ];
        wantedBy = [ "graphical.target" ];
        path = [ pkgs.coreutils ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "thunderbolt-retrigger" ''
            sleep 5
            for dev in /sys/bus/thunderbolt/devices/*/device_name; do
              dir=$(dirname "$dev")
              if [ -f "$dir/authorized" ] && grep -q "Thunderbolt 4 100W G6" "$dev" 2>/dev/null; then
                echo "Re-triggering $dir"
                echo 0 > "$dir/authorized"
                sleep 1
                echo 1 > "$dir/authorized"
              fi
            done
          '';
          RemainAfterExit = true;
        };
      };
    };
}
