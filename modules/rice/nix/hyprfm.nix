# HyprFM follows the active rice theme (D-055). rice-hyprfm-theme writes
# ~/.config/hyprfm/themes/rice.toml (on activation, rice-switch, and a
# daily-accent change) and HyprFM reloads it live. HyprFM rewrites its own
# config.toml from the Settings panel, so Home Manager never owns that
# file: activation only points its `theme` at "rice", the way upstream
# documents scripts doing it.
_: {
  flake.homeModules.rice-hyprfm =
    { lib, pkgs, config, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      adapter = (import ./_switch-package.nix { inherit pkgs; }).hyprfmTheme;
      sed = "${pkgs.gnused}/bin/sed";
      grep = "${pkgs.gnugrep}/bin/grep";
    in
    {
      config = lib.mkIf ((cfg.enable or false) && osConfig.environment.desktop.windowManager == "hyprland") {
        home.activation.riceHyprfm = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          hyprfm_conf="${config.xdg.configHome}/hyprfm/config.toml"
          if [ -n "''${DRY_RUN:-}" ]; then
            verboseEcho "rice-hyprfm: would point $hyprfm_conf at the rice theme"
          else
            mkdir -p "$(dirname "$hyprfm_conf")"
            if [ ! -e "$hyprfm_conf" ]; then
              printf '[general]\ntheme = "rice"\n' > "$hyprfm_conf"
            elif ! ${grep} -qx 'theme = "rice"' "$hyprfm_conf"; then
              # The set line, else the commented default under [general],
              # else a new [general] table.
              if ${grep} -qE '^theme *=' "$hyprfm_conf"; then
                ${sed} -i -E 's/^theme *=.*/theme = "rice"/' "$hyprfm_conf"
              elif ${grep} -qE '^# *theme *=' "$hyprfm_conf"; then
                ${sed} -i -E '0,/^# *theme *=.*/s//theme = "rice"/' "$hyprfm_conf"
              elif ${grep} -qx '\[general\]' "$hyprfm_conf"; then
                ${sed} -i '/^\[general\]$/a theme = "rice"' "$hyprfm_conf"
              else
                printf '\n[general]\ntheme = "rice"\n' >> "$hyprfm_conf"
              fi
            fi
            ${adapter}/bin/rice-hyprfm-theme --active ||
              warnEcho "rice-hyprfm: could not write HyprFM colours"
          fi
        '';
      };
    };
}
