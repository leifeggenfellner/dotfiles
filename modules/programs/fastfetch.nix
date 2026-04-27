_: {
  flake.homeModules.programs-fastfetch =
    { pkgs, lib, osConfig, ... }:
    {
      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        home.packages = [ pkgs.fastfetch ];

        xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          logo = {
            source = "~/.config/fastfetch/totoro.txt";
            type = "file";
            padding = {
              top = 1;
              left = 2;
              right = 3;
            };
          };
          display = {
            separator = "  ";
            key.width = 10;
            color = {
              keys = "blue";
              title = "magenta";
            };
          };
          modules = [
            "break"
            {
              type = "title";
              format = "{user-name}@{host-name}";
            }
            "separator"
            {
              type = "os";
              key = " OS";
            }
            {
              type = "kernel";
              key = " Kernel";
            }
            {
              type = "uptime";
              key = "󰅐 Uptime";
            }
            {
              type = "packages";
              key = "󰏗 Packages";
            }
            {
              type = "shell";
              key = " Shell";
            }
            {
              type = "wm";
              key = " WM";
            }
            {
              type = "terminal";
              key = " Terminal";
            }
            "break"
            {
              type = "cpu";
              key = "󰻠 CPU";
            }
            {
              type = "gpu";
              key = "󰍹 GPU";
            }
            {
              type = "memory";
              key = "󰑭 Memory";
            }
            {
              type = "disk";
              key = "󰋊 Disk";
              folders = "/";
            }
            "break"
            "colors"
          ];
        };

        xdg.configFile."fastfetch/totoro.txt".source = ./fastfetch/totoro.txt;
      };
    };
}
