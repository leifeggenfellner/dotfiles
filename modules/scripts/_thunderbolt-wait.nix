{ pkgs, ... }:

pkgs.writeShellScriptBin "thunderbolt-wait" ''
  set -euo pipefail

  BOLTCTL=${pkgs.bolt}/bin/boltctl
  MAX_WAIT=15
  POLL_INTERVAL=1

  echo "=== Thunderbolt dock scan ==="

  # Authorize any devices that bolt knows about but haven't been authorized yet
  authorize_devices() {
    $BOLTCTL list 2>/dev/null | grep -oP '^\s+uuid:\s+\K\S+' | while read -r uuid; do
      status=$($BOLTCTL info "$uuid" 2>/dev/null | grep -oP '^\s+status:\s+\K\S+' || echo "unknown")
      if [ "$status" = "connected" ] || [ "$status" = "authorized" ]; then
        echo "Device $uuid already authorized/connected"
      else
        echo "Authorizing device $uuid (status: $status)"
        $BOLTCTL authorize "$uuid" 2>/dev/null || true
      fi
    done
  }

  # Also poke sysfs directly for devices bolt might not track yet
  authorize_sysfs() {
    for dev in /sys/bus/thunderbolt/devices/*/authorized; do
      dir=$(dirname "$dev")
      name=""
      if [ -f "$dir/device_name" ]; then
        name=$(cat "$dir/device_name" 2>/dev/null || echo "unknown")
      fi
      current=$(cat "$dev" 2>/dev/null || echo "1")
      if [ "$current" = "0" ]; then
        echo "Authorizing sysfs device: $name ($dir)"
        echo 1 > "$dev" 2>/dev/null || true
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

  # If no thunderbolt devices exist at all, skip immediately (laptop-only, no dock)
  tb_device_count=$(find /sys/bus/thunderbolt/devices/ -maxdepth 1 -mindepth 1 -type l 2>/dev/null | wc -l)
  if [ "$tb_device_count" -eq 0 ]; then
    echo "No Thunderbolt devices found — laptop only, skipping"
    exit 0
  fi

  authorize_sysfs
  authorize_devices

  # Wait for at least one non-laptop monitor to appear via hyprctl
  echo "Waiting for dock displays..."
  waited=0
  while [ "$waited" -lt "$MAX_WAIT" ]; do
    monitor_count=$(hyprctl monitors -j 2>/dev/null | ${pkgs.jq}/bin/jq 'length' 2>/dev/null || echo "0")
    if [ "$monitor_count" -gt 1 ]; then
      echo "Detected $monitor_count monitors — dock displays are online"
      exit 0
    fi
    sleep "$POLL_INTERVAL"
    waited=$((waited + POLL_INTERVAL))

    # Re-authorize on each poll in case devices appeared late
    authorize_sysfs
  done

  echo "Timeout after ''${MAX_WAIT}s — only laptop display found, proceeding anyway"
''
