{ pkgs, lib, ... }:
{
  ########################################################################
  # Power / Performance Policy (TLP as single manager)
  ########################################################################

  powerManagement.powertop.enable = lib.mkForce false;

  services = {
    power-profiles-daemon.enable = false;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;

        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";

        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";

        USB_AUTOSUSPEND = 1;

        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 85;
      };
    };

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8153", TEST=="power/control", ATTR{power/control}="auto"
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="8156", TEST=="power/control", ATTR{power/control}="auto"

      SUBSYSTEM=="power_supply", KERNEL=="AC", ACTION=="change", TAG+="systemd", ENV{SYSTEMD_WANTS}+="rapl-floor.service"
      SUBSYSTEM=="thunderbolt", ACTION=="add", TAG+="systemd", ENV{SYSTEMD_WANTS}+="rapl-floor.service"
    '';
  };

  # The HP EC sometimes drops the MMIO package limit to 10-20 W after a
  # resume or dock hand-off (seen on the TB4 G6 dock) and never restores
  # it; the GPU then sits at ~150 MHz and page flips stall. On AC, raise
  # the limits back to the 165H's 28 W base. Never lowers a limit.
  systemd.services.rapl-floor = {
    description = "Restore RAPL MMIO power limit floor on AC";
    after = [
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    wantedBy = [
      "multi-user.target"
      "suspend.target"
      "hibernate.target"
      "hybrid-sleep.target"
      "suspend-then-hibernate.target"
    ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "rapl-floor" ''
        floor=28000000
        zone=/sys/class/powercap/intel-rapl-mmio:0

        apply() {
          [ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" = 1 ] || return 0
          # 0 = long_term, 1 = short_term.
          for i in 0 1; do
            limit=$zone/constraint_''${i}_power_limit_uw
            [ -w "$limit" ] || continue
            current=$(cat "$limit")
            if [ "$current" -lt "$floor" ]; then
              echo "Raising $(cat $zone/constraint_''${i}_name) from $current to $floor uW"
              echo "$floor" > "$limit"
            fi
          done
        }

        # The EC applies its own limit a few seconds after the event, so
        # check once it has settled and again later in case it re-clamps.
        sleep 5
        apply
        sleep 25
        apply
      '';
    };
  };

  boot = {
    kernelParams = [
      "intel_pstate=active"
      "nmi_watchdog=0"
      "i915.enable_fbc=0"
      "i915.enable_psr=0"
      "i915.enable_dc=0"
    ];

    kernel.sysctl."vm.dirty_writeback_centisecs" = 1500;

    extraModprobeConfig = ''
      options snd_hda_intel power_save=1 power_save_controller=Y
      options btusb enable_autosuspend=Y
    '';
  };

  environment.systemPackages = with pkgs; [
    powertop
    linuxPackages_latest.turbostat
  ];
}
