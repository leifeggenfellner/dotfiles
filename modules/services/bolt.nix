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
        after = [ "bolt.service" "graphical.target" "systemd-modules-load.service" ];
        wantedBy = [ "graphical.target" ];
        path = [ pkgs.coreutils pkgs.bolt pkgs.gawk pkgs.systemd ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "thunderbolt-rescan" ''
            intel_drm_ready() {
              [ -d /sys/module/i915 ] || return 1

              for status in /sys/class/drm/card*-*/status; do
                [ -e "$status" ] || continue
                driver="$${status%/status}/device/driver"
                [ -e "$driver" ] || continue
                [ "$(basename "$(readlink -f "$driver")")" = "i915" ] && return 0
              done

              return 1
            }

            waited=0
            while ! intel_drm_ready && [ "$waited" -lt 20 ]; do
              echo "Waiting for Intel DRM connector readiness..."
              sleep 1
              waited=$((waited + 1))
            done

            if intel_drm_ready; then
              echo "Intel DRM connector ready after $waited second(s)"
            else
              echo "Intel DRM connector not ready after $waited second(s); reprobeing anyway"
            fi

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
