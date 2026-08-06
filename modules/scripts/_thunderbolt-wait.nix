{ pkgs, ... }:

pkgs.writeShellScriptBin "thunderbolt-wait" ''
  set -euo pipefail

  BOLTCTL=${pkgs.bolt}/bin/boltctl
  JQ=${pkgs.jq}/bin/jq
  MAX_WAIT=30
  POLL_INTERVAL=1

  echo "=== Thunderbolt/USB4 dock scan ==="

  # Authorize any devices that bolt knows about but haven't been authorized yet
  authorize_devices() {
    # Parse peripheral UUIDs from boltctl list -a. Skip host domains.
    $BOLTCTL list -a 2>/dev/null | awk '
      /^ \*/ { if (uuid != "" && type == "peripheral") print uuid; uuid=""; type="" }
      /type:[[:space:]]*/ { type=$NF }
      /uuid:[[:space:]]*/ { uuid=$NF }
      END { if (uuid != "" && type == "peripheral") print uuid }
    ' | while read -r uuid; do
      [ -n "$uuid" ] || continue
      status=$($BOLTCTL info "$uuid" 2>/dev/null | sed -n 's/.*status:[[:space:]]*//p' | head -n1 | awk '{print $1}')
      case "$status" in
        connected|authorized)
          echo "Device $uuid already $status"
          ;;
        *)
          echo "Authorizing device $uuid (status: ''${status:-unknown})"
          $BOLTCTL authorize "$uuid" 2>/dev/null || true
          ;;
      esac
    done
  }

  # Also poke sysfs directly for devices bolt might not track yet
  authorize_sysfs() {
    for dev in /sys/bus/thunderbolt/devices/*/authorized; do
      [ -e "$dev" ] || continue
      dir=$(dirname "$dev")
      name=""
      if [ -f "$dir/device_name" ]; then
        name=$(cat "$dir/device_name" 2>/dev/null || echo "unknown")
      fi
      current=$(cat "$dev" 2>/dev/null || echo "1")
      if [ "$current" = "0" ]; then
        if [ -w "$dev" ]; then
          echo "Authorizing sysfs device: $name ($dir)"
          printf '1\n' > "$dev" || true
        else
          echo "Sysfs device needs root authorization: $name ($dir)"
        fi
      fi
    done
  }

  # Wait for thunderbolt controller to appear
  waited=0
  while [ ! -d /sys/bus/thunderbolt/devices ] && [ "$waited" -lt 5 ]; do
    echo "Waiting for Thunderbolt bus..."
    sleep "$POLL_INTERVAL"
    waited=$((waited + POLL_INTERVAL))
  done

  dock_present() {
    # Any non-domain bolt peripheral indicates an attached device/dock.
    $BOLTCTL list -a 2>/dev/null | grep -q "type:[[:space:]]*peripheral"
  }

  drm_external_connected() {
    for st in /sys/class/drm/card*-*/status; do
      [ -e "$st" ] || continue
      case "$st" in
        *eDP*|*LVDS*) continue ;;
      esac
      if [ "$(cat "$st" 2>/dev/null || true)" = "connected" ]; then
        return 0
      fi
    done
    return 1
  }

  # If neither bolt nor DRM sees an external endpoint, skip quickly.
  if ! dock_present && ! drm_external_connected; then
    echo "No dock/external connectors detected — skipping"
    exit 0
  fi

  authorize_sysfs
  authorize_devices

  # Wait for at least one non-laptop monitor to appear via Hyprland,
  # but keep probing external connector state while waiting.
  echo "Waiting for dock displays..."
  waited=0
  while [ "$waited" -lt "$MAX_WAIT" ]; do
    monitor_count=$(hyprctl monitors -j 2>/dev/null | $JQ 'length' 2>/dev/null || echo "0")
    external_count=$(hyprctl monitors -j 2>/dev/null | $JQ '[.[] | select(.name != "eDP-1")] | length' 2>/dev/null || echo "0")
    if [ "$monitor_count" -gt 1 ] || [ "$external_count" -gt 0 ]; then
      echo "Detected external monitor(s) — dock displays are online"
      # Wake monitors that may have gone to DPMS sleep during boot
      hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "on" }))' >/dev/null 2>&1 || true
      exit 0
    fi
    sleep "$POLL_INTERVAL"
    waited=$((waited + POLL_INTERVAL))

    # Re-authorize on each poll in case devices appeared late
    authorize_sysfs
    authorize_devices

    # Poke DPMS periodically to wake any sleeping monitors
    hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "on" }))' >/dev/null 2>&1 || true

    # Trigger monitor rescan in Hyprland in case DP links appeared after auth.
    hyprctl eval 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })' >/dev/null 2>&1 || true
  done

  # Final DPMS wake even on timeout — monitors may have appeared but gone to sleep
  hyprctl eval 'hl.dispatch(hl.dsp.dpms({ action = "on" }))' >/dev/null 2>&1 || true
  echo "Timeout after ''${MAX_WAIT}s — only laptop display found, proceeding anyway"
''
