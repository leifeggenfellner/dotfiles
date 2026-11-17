# HyprFM follows the active rice theme (D-055). rice-hyprfm-theme writes
# ~/.config/hyprfm/themes/rice.toml and a "rice" icon theme of recoloured
# folders (on activation, rice-switch, and a daily-accent change), and
# HyprFM reloads both live. HyprFM rewrites its own
# config.toml from the Settings panel, so Home Manager never owns that
# file: activation only points its `theme` and `icon_theme` at "rice",
# the way upstream documents scripts doing it.
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
            verboseEcho "rice-hyprfm: would point $hyprfm_conf at the rice theme and icons"
          else
            # Sets a [general] key: the set line, else its commented
            # default, else a new key under [general] (added if missing).
            hyprfm_set() {
              local key="$1" value="$2"
              if ${grep} -qx "$key = $value" "$hyprfm_conf"; then
                return
              elif ${grep} -qE "^$key *=" "$hyprfm_conf"; then
                ${sed} -i -E "s/^$key *=.*/$key = $value/" "$hyprfm_conf"
              elif ${grep} -qE "^# *$key *=" "$hyprfm_conf"; then
                ${sed} -i -E "0,/^# *$key *=.*/s//$key = $value/" "$hyprfm_conf"
              else
                ${grep} -qx '\[general\]' "$hyprfm_conf" || printf '\n[general]\n' >> "$hyprfm_conf"
                ${sed} -i "/^\[general\]$/a $key = $value" "$hyprfm_conf"
              fi
            }
            mkdir -p "$(dirname "$hyprfm_conf")"
            [ -e "$hyprfm_conf" ] || printf '[general]\n' > "$hyprfm_conf"
            hyprfm_set theme '"rice"'
            hyprfm_set icon_theme '"rice"'
            ${adapter}/bin/rice-hyprfm-theme --active ||
              warnEcho "rice-hyprfm: could not write HyprFM colours"
          fi
        '';
      };
    };
}
