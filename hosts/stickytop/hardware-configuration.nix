# TODO: Regenerate on the actual machine with:
#   nixos-generate-config --show-hardware-config > hardware-configuration.nix
#
# This is a placeholder based on the Asus ZenBook 14 UX3402 (Alder Lake i5).
{ config, lib, modulesPath, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "sd_mod"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # Placeholder — update with actual UUIDs after install
  # fileSystems."/" = { ... };
  # fileSystems."/boot" = { ... };
  # swapDevices = [ ... ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
