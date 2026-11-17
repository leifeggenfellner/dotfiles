# Read-only terminal consumers of the active rice (D-042): rice-query for
# shell tools, rice-terminal for the fish greeting and command-not-found
# line. The greeting's line appends to whatever fish_greeting other modules
# define, but is resolved first: a draw it claims picks today's card (D-054).
_: {
  flake.homeModules.rice-query =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };
      packages = import ./_query-package.nix { inherit pkgs; };
      riceTerminal = "${packages.riceTerminal}/bin/rice-terminal";
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [ packages.riceQuery packages.riceTerminal ];

        # The active theme, resolved once per interactive shell for the
        # prompt (D-050) and the greeting card (D-051).
        programs.fish.interactiveShellInit = lib.mkOrder 400 ''
          set -g __rice_active (rice-query active 2>/dev/null)
        '';

        programs.fish.functions = {
          fish_greeting = lib.mkMerge [
            (lib.mkBefore ''
              set -l __rice_tty 0
              isatty stdout; and set __rice_tty 1
              set -l __rice_omen (RICE_TERMINAL_COLOR=$__rice_tty ${riceTerminal} greeting 2>/dev/null | string collect)
            '')
            (lib.mkAfter ''
              test -n "$__rice_omen"; and printf '%s\n' $__rice_omen
            '')
          ];
          fish_command_not_found = ''
            ${riceTerminal} command-not-found (string escape -- $argv[1]) >&2 2>/dev/null
            or __fish_default_command_not_found_handler $argv
          '';
        };
      };
    };
}
