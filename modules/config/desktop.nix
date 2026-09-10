_: {
  flake.nixosModules.config-desktop =
    { config, lib, ... }:
    {
      options.environment.desktop = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable desktop environment";
        };
        windowManager = lib.mkOption {
          type = lib.types.nullOr (lib.types.enum [ "hyprland" "gnome" ]);
          default = "hyprland";
          description = "Set what window manager to use.";
        };
        hyprland.configPath = lib.mkOption {
          type = lib.types.str;
          default = "${config.users.users.leif.home}/.config/hypr/hyprland.lua";
          readOnly = true;
          description = "Absolute path to the Nix-generated Hyprland Lua config.";
        };
        develop = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Development toolchain";
        };
      };
    };
}
