{
  services.hardware.bolt.enable = true;

  # Re-authorize Thunderbolt dock after boot to fix DP tunnel race condition
  # The DP tunnel often fails during early boot on Meteor Lake
  systemd.services.thunderbolt-retrigger = {
    description = "Re-trigger Thunderbolt DP tunnels";
    after = [ "bolt.service" "graphical.target" ];
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/bin/sh -c 'sleep 5 && echo 0 > /sys/bus/thunderbolt/devices/0-1/authorized; sleep 1; echo 1 > /sys/bus/thunderbolt/devices/0-1/authorized'";
      RemainAfterExit = true;
    };
  };
}
