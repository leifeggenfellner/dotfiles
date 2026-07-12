# Installs the rice runtime as the named Quickshell config "rice"
# (~/.config/quickshell/rice) and ships the rice-shell launcher.
# Prod instance: `quickshell -c rice`; keybinds address it the same
# way for IPC. Dev instances run from the repo via `rice-shell --dev`.
_: {
  flake.homeModules.rice-shell =
    { lib, pkgs, osConfig, ... }:
    let
      cfg = osConfig.rice or { enable = false; };

      qtMediaDeps = [
        pkgs.qt6.qtmultimedia
      ];
      qtMediaQmlPath = lib.makeSearchPath "lib/qt-6/qml" qtMediaDeps;
      qtMediaPluginPath = lib.makeSearchPath "lib/qt-6/plugins" qtMediaDeps;

      rice-sound-play = pkgs.writeShellScriptBin "rice-sound-play" ''
        set -euo pipefail
        file="''${1:-}"
        if [ -z "$file" ]; then
          echo "rice-sound-play: missing sound file" >&2
          exit 64
        fi
        exec ${pkgs.pipewire}/bin/pw-play --volume 0.35 "$file"
      '';

      rice-runtime = pkgs.runCommand "rice-quickshell-runtime"
        { nativeBuildInputs = [ pkgs.qt6.qtshadertools ]; } ''
        cp -R ${../runtime/quickshell} "$out"
        chmod -R u+w "$out"

        shader_dir="$out/components/effects/shaders"
        if [ -d "$shader_dir" ]; then
          compiled=()
          for shader in "$shader_dir"/*.frag; do
            [ -e "$shader" ] || continue
            name="$(basename "$shader" .frag)"
            qsb --qt6 --silent -o "$shader_dir/$name.qsb" "$shader"
            compiled+=("$name")
          done

          printf '{"compiled":[' > "$shader_dir/manifest.json"
          first=1
          for name in "''${compiled[@]}"; do
            if [ "$first" -eq 0 ]; then
              printf ',' >> "$shader_dir/manifest.json"
            fi
            first=0
            printf '"%s"' "$name" >> "$shader_dir/manifest.json"
          done
          printf ']}' >> "$shader_dir/manifest.json"
        fi
      '';

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

      rice-lock-screen = pkgs.writeShellScriptBin "rice-lock-screen" ''
        set -euo pipefail

        mode="prod"

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --dev) mode="dev" ;;
            --prod) mode="prod" ;;
            -h|--help)
              cat <<'USAGE'
        Usage: rice-lock-screen [--dev|--prod]

          --prod       Run the installed ~/.config/quickshell/rice/lock.qml root.
          --dev        Run lock.qml directly from the dotfiles checkout.

        Optional environment overrides:
          RICE_LOCK_MODE=image|video
          RICE_LOCK_IMAGE=/path/to/image
          RICE_LOCK_VIDEO=/path/to/loop.mp4
        USAGE
              exit 0 ;;
            *) echo "rice-lock-screen: unknown option: $1" >&2; exit 1 ;;
          esac
          shift
        done

        export QML2_IMPORT_PATH="${qtMediaQmlPath}''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
        export QT_PLUGIN_PATH="${qtMediaPluginPath}''${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
        export QT_MEDIA_BACKEND="''${QT_MEDIA_BACKEND:-ffmpeg}"

        if [ "$mode" = "dev" ]; then
          repo_root="''${DOTFILES:-$HOME/Sources/dotfiles}"
          lock_root="$repo_root/modules/rice/runtime/quickshell/lock.qml"
        else
          lock_root="$HOME/.config/quickshell/rice/lock.qml"
        fi

        exec ${pkgs.quickshell}/bin/quickshell --no-duplicate --path "$lock_root"
      '';
    in
    {
      config = lib.mkIf (cfg.enable or false) {
        home.packages = [
          pkgs.quickshell
          pkgs.qt6.qtmultimedia
          rice-lock-screen
          rice-shell
          rice-sound-play
        ];
        xdg.configFile."quickshell/rice".source = rice-runtime;
      };
    };
}
