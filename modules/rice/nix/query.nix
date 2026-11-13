# Read-only terminal consumers of the active rice (D-042): rice-query for
# shell tools, rice-terminal for the fish greeting and command-not-found
# line. The greeting appends to whatever fish_greeting other modules define.
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

        programs.fish.functions = {
          fish_greeting = lib.mkAfter ''
            ${riceTerminal} greeting 2>/dev/null
          '';
          fish_command_not_found = ''
            ${riceTerminal} command-not-found (string escape -- $argv[1]) >&2 2>/dev/null
            or __fish_default_command_not_found_handler $argv
          '';
        };
      };
    };
}
