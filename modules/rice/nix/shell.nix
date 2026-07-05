# Installs the rice runtime as the named Quickshell config "rice"
# (~/.config/quickshell/rice) and ships the rice-shell launcher.
# Prod instance: `quickshell -c rice`; keybinds address it the same
# way for IPC. Dev instances run from the repo via `rice-shell --dev`.
_: {
  flake.homeModules.rice-shell =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };

      rice-shell = pkgs.writeShellScriptBin "rice-shell" ''
        set -euo pipefail

        mode="prod"
        foreground="0"

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --dev) mode="dev" ;;
            --prod) mode="prod" ;;
            -f|--foreground) foreground="1" ;;
            -h|--help)
              cat <<'USAGE'
        Usage: rice-shell [--dev|--prod] [--foreground]

          --prod       Run the installed ~/.config/quickshell/rice config (default).
          --dev        Run from the repo runtime (no rebuild needed). NOTE: the
                       prod keybind IPC (quickshell -c rice ipc ...) does not reach
                       a dev instance; address it with -p <repo path> instead.
          -f           Stay in the foreground with logs visible.
        USAGE
              exit 0 ;;
            *) echo "rice-shell: unknown option: $1" >&2; exit 1 ;;
          esac
          shift
        done

        # Stop only rice instances; other quickshell configs are untouched.
        quickshell kill -c rice 2>/dev/null || true
        pkill -f "quickshell (-c|--config) rice" 2>/dev/null || true
        pkill -f "quickshell (-p|--path) .*rice/runtime/quickshell" 2>/dev/null || true

        if [ "$mode" = "dev" ]; then
          repo_root="''${DOTFILES:-$HOME/Sources/dotfiles}"
          args=(--path "$repo_root/modules/rice/runtime/quickshell")
        else
          args=(--config rice)
        fi

        if [ "$foreground" = "1" ]; then
          exec quickshell "''${args[@]}"
        else
          setsid -f quickshell "''${args[@]}" >/dev/null 2>&1
        fi
      '';
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [
          pkgs.quickshell
          rice-shell
        ];
        xdg.configFile."quickshell/rice".source = ../runtime/quickshell;
      };
    };
}
