_: {
  flake.homeModules.programs-qt =
    { lib
    , pkgs
    , config
    , osConfig
    , ...
    }:
    let
      KvLibadwaita = pkgs.fetchFromGitHub {
        owner = "GabePoel";
        repo = "KvLibadwaita";
        rev = "87c1ef9f44ec48855fd09ddab041007277e30e37";
        hash = "sha256-K/2FYOtX0RzwdcGyeurLXAh3j8ohxMrH2OWldqVoLwo=";
        sparseCheckout = [ "src" ];
      };

      qtctConf = {
        Appearance = {
          custom_palette = false;
          icon_theme = config.gtk.iconTheme.name;
          standard_dialogs = "xdgdesktopportal";
          style = "kvantum";
        };
      };

      defaultFont = "${config.gtk.font.name},${builtins.toString config.gtk.font.size}";

      # KvLibadwaita Dark recoloured from the active palette: its greys map
      # to the palette's surfaces by lightness and its blue to the accent.
      # Pure white and black stay, the SVG uses them as tints.
      c = name: config.theme.colors.${name};
      accent = c config.theme.style.accentPrimary;
      sharedColours = {
        "1e1e1e" = c "crust";
        "212121" = c "crust";
        "242424" = c "crust";
        "282828" = c "mantle";
        "2c2c2c" = c "base";
        "2e2e2e" = c "mantle";
        "303030" = c "base";
        "31363b" = c "surface0";
        "323232" = c "surface0";
        "3d3d3d" = c "surface0";
        "404040" = c "surface1";
        "414141" = c "surface1";
        "444444" = c "surface1";
        "474747" = c "surface1";
        "4b4b4b" = c "surface1";
        "4d4d4d" = c "surface1";
        "4f4f4f" = c "surface1";
        "525252" = c "surface2";
        "535353" = c "surface2";
        "5a5a5a" = c "surface2";
        "616161" = c "surface2";
        "646464" = c "surface2";
        "666666" = c "surface2";
        "696969" = c "overlay0";
        "6e6e6e" = c "overlay0";
        "707070" = c "overlay0";
        "787878" = c "overlay0";
        "797979" = c "overlay0";
        "989898" = c "overlay1";
        "b6b6b6" = c "overlay2";
        "c1c1c1" = c "subtext0";
        "dedede" = c "text";
        "dfdfdf" = c "text";
        "efefef" = c "text";
        "3584e4" = accent;
        "4990e7" = accent;
        "4285f4" = accent;
        "3daee9" = accent;
        "93cee9" = accent;
        "b74aff" = accent;
        "0057ae" = accent;
        "587392" = accent;
        "e040fb" = c "peach";
        "f04a50" = c "red";
      };
      # In the config white is text on the accent (pressed, toggled,
      # selected), which needs to be dark on a light accent.
      configColours = sharedColours // { "ffffff" = c "crust"; };
      recolour = colours: file: lib.concatStringsSep " "
        (lib.mapAttrsToList
          (from: to: "-e 's/#${from}/#${to}/gI'")
          colours) + " ${file}";
      kvantumRice = pkgs.runCommand "kvantum-rice" { } ''
        mkdir -p $out
        sed ${recolour configColours "${KvLibadwaita}/src/KvLibadwaita/KvLibadwaitaDark.kvconfig"} > $out/KvRice.kvconfig
        sed ${recolour sharedColours "${KvLibadwaita}/src/KvLibadwaita/KvLibadwaitaDark.svg"} > $out/KvRice.svg
      '';
    in
    {

      config = lib.mkIf (osConfig.environment.desktop.windowManager == "hyprland") {
        qt = {
          enable = true;
          platformTheme.name = "qtct";
        };

        home.packages = [
          pkgs.qt6Packages.qtstyleplugin-kvantum
          pkgs.qt6Packages.qt6ct
          pkgs.libsForQt5.qtstyleplugin-kvantum
          pkgs.libsForQt5.qt5ct
        ];

        xdg.configFile = {
          # Kvantum config
          "Kvantum" = {
            source = "${KvLibadwaita}/src";
            recursive = true;
          };

          "Kvantum/KvRice".source = kvantumRice;

          "Kvantum/kvantum.kvconfig".text = ''
            [General]
            theme=KvRice
          '';

          # qtct config
          "qt5ct/qt5ct.conf".text =
            let
              default = ''"${defaultFont},-1,5,50,0,0,0,0,0"'';
            in
            lib.generators.toINI { } (
              qtctConf
              // {
                Fonts = {
                  fixed = default;
                  general = default;
                };
              }
            );

          "qt6ct/qt6ct.conf".text =
            let
              default = ''"${defaultFont},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular"'';
            in
            lib.generators.toINI { } (
              qtctConf
              // {
                Fonts = {
                  fixed = default;
                  general = default;
                };
              }
            );
        };
      };
    };
}
