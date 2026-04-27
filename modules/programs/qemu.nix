_: {
  flake.nixosModules.programs-qemu =
    { lib, pkgs, config, ... }:
    let
      cfg = config.program.qemu;
    in
    {
      options.program.qemu = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Virt-Manager.";
        };
      };

      config = lib.mkIf (cfg.enable && config.environment.desktop.enable) {
        programs = {
          virt-manager.enable = true;
        };

        services = {
          spice-vdagentd.enable = true;
        };

        virtualisation = {
          libvirtd = {
            enable = true;
            qemu = {
              package = pkgs.qemu_kvm;
              swtpm.enable = true;
            };
          };
          spiceUSBRedirection.enable = true;
        };
        environment = {
          systemPackages = with pkgs; [
            spice
            spice-vdagent
            spice-autorandr
            spice-gtk
            spice-protocol
            virt-viewer
            virtio-win
            win-spice
            virtio-win
          ];
          persistence."/persist" = {
            directories = [
              "/var/lib/libvirt/images"
            ];
          };
        };

        users.users.leif.extraGroups = [ "libvirtd" ];
      };
    };
}
