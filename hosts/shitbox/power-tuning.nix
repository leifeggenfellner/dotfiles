{ pkgs, lib, ... }:
{
  ########################################################################
  # Power / Performance Policy (TLP as single manager)
  ########################################################################

  # Ensure powertop autotune is OFF (we still install the tool).
  powerManagement.powertop.enable = lib.mkForce false;

  services = {
    # Disable power-profiles-daemon so it doesn't override TLP.
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
    '';
  };

  boot = {
    kernelParams = [
      "intel_pstate=active"
      "nmi_watchdog=0"
      # Temporarily disable PSR / DC / FBC to test flicker sources:
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
