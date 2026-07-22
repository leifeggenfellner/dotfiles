_: {
  flake.homeModules.programs-lotm-lockscreen =
    { lib, config, osConfig, ... }:
    let
      cfg = config.program.lotm-lockscreen;
      riceCfg = osConfig.rice or { enable = false; };
    in
    {
      options.program.lotm-lockscreen = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Emit LOTM lockscreen tuning as home.sessionVariables, so
            rice-lock-screen picks them up whenever it selects
            variant=lotm. The module only exports non-default values,
            so the QML stays at its built-in LOTM defaults unless you opt in.
          '';
        };

        fontFamily = lib.mkOption {
          type = lib.types.str;
          default = "";
          example = "Cinzel";
          description = ''
            Override the bundled Cinzel-Bold with an installed font
            family. Empty keeps the .ttf that ships with the LOTM
            lockscreen asset directory.
          '';
        };

        powerRow = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            Show the REBOOT/SHUTDOWN row. Turn off when the rice
            dashboard already surfaces those actions elsewhere.
          '';
        };

        overlay = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Composite two slow accent-tinted fog bands above the video
            (below the UI) for a subtle rice atmosphere.
          '';
        };

        chime = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Play the active rice theme's notification sound on unlock.
            The sound path is exported automatically by rice-lock-screen
            from `assets.sounds.notification` when the theme has one.
          '';
        };
      };

      config = lib.mkIf (cfg.enable && (riceCfg.enable or false)) {
        home.sessionVariables =
          (lib.optionalAttrs (cfg.fontFamily != "") {
            RICE_LOTM_LOCK_FONT_FAMILY = cfg.fontFamily;
          })
          // (lib.optionalAttrs (!cfg.powerRow) {
            RICE_LOTM_LOCK_POWER_ROW = "off";
          })
          // (lib.optionalAttrs cfg.overlay {
            RICE_LOTM_LOCK_OVERLAY = "on";
          })
          // (lib.optionalAttrs cfg.chime {
            RICE_LOTM_LOCK_CHIME = "on";
          });
      };
    };
}
