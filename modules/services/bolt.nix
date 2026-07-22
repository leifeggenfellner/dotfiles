_: {
  flake.nixosModules.services-bolt =
    { pkgs, ... }:
    {
      services.hardware.bolt.enable = true;

      # On hot-plug, ask bolt to authorize pending devices and nudge DRM udev.
      # Do not toggle Thunderbolt authorization here: deauth/re-auth emits more
      # thunderbolt change events and can flap the dock before DP tunnels settle.
      services.udev.extraRules = ''
        SUBSYSTEM=="thunderbolt", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}="thunderbolt-rescan.service"
      '';

      systemd.services.thunderbolt-rescan = {
        description = "Authorize Thunderbolt devices and rescan display connectors";
        after = [ "bolt.service" "graphical.target" ];
        wantedBy = [ "graphical.target" ];
        path = [ pkgs.coreutils pkgs.bolt pkgs.gawk pkgs.systemd ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "thunderbolt-rescan" ''
            sleep 3

            # Authorize any pending peripheral via boltctl. Skip host domains.
            boltctl list -a 2>/dev/null | awk '
              /^ \*/ { if (uuid != "" && type == "peripheral") print uuid; uuid=""; type="" }
              /type:[[:space:]]*/ { type=$NF }
              /uuid:[[:space:]]*/ { uuid=$NF }
              END { if (uuid != "" && type == "peripheral") print uuid }
            ' | while read -r uuid; do
              [ -n "$uuid" ] || continue
              status=$(boltctl info "$uuid" 2>/dev/null | sed -n 's/.*status:[[:space:]]*//p' | head -n1 | awk '{print $1}')
              if [ "$status" != "authorized" ] && [ "$status" != "connected" ]; then
                echo "Authorizing $uuid (status: $status)"
                boltctl authorize "$uuid" 2>/dev/null || true
              fi
            done

            udevadm settle --timeout=5 || true
            udevadm trigger --subsystem-match=drm --action=change || true
          '';
        };
      };
    };
}
