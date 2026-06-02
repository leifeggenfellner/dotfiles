_: {
  flake.nixosModules.hardware-graphics =
    { pkgs, ... }:
    {
      hardware.graphics.enable = true;

      environment.systemPackages = with pkgs; [
        vulkan-tools
        mesa-demos
      ];
    };
}
