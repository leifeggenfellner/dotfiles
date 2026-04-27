_: {
  flake.nixosModules.services-bolt =
    { pkgs, ... }:
    {
      services.hardware.bolt.enable = true;

      systemd.services.thunderbolt-retrigger = {
        description = "Re-trigger Thunderbolt DP tunnels";
        after = [ "bolt.service" "graphical.target" ];
        wantedBy = [ "graphical.target" ];
        path = [ pkgs.coreutils pkgs.bolt ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "thunderbolt-retrigger" ''
            sleep 3

            # Authorize any pending devices via boltctl
            boltctl list 2>/dev/null | grep -oP '^\s+uuid:\s+\K\S+' | while read -r uuid; do
              status=$(boltctl info "$uuid" 2>/dev/null | grep -oP '^\s+status:\s+\K\S+' || echo "unknown")
              if [ "$status" != "authorized" ] && [ "$status" != "connected" ]; then
                echo "Authorizing $uuid (status: $status)"
                boltctl authorize "$uuid" 2>/dev/null || true
              fi
            done

            # Re-trigger DP tunnels on known dock hardware
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
