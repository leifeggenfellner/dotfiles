{ pkgs }:

pkgs.writeShellScriptBin "reload-bar" ''
    set -euo pipefail

    mode="prod"
    foreground="0"

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --dev)
          mode="dev"
          ;;
        --prod)
          mode="prod"
          ;;
        --foreground|-f)
          foreground="1"
          ;;
        --help|-h)
          cat <<'USAGE'
  Usage: reload-bar [--dev|--prod] [--foreground]

  Options:
    --dev         Run quickshell directly from the repo UI path (no rebuild required).
    --prod        Run the installed ~/.config/quickshell config (default).
    -f, --foreground
                  Run in the foreground with logs visible.
  USAGE
          exit 0
          ;;
        *)
          echo "reload-bar: unknown option: $1" >&2
          exit 1
          ;;
      esac
      shift
    done

    stop_quickshell() {
      # Ask quickshell itself to terminate all instances first.
      quickshell kill --all >/dev/null 2>&1 || true

      # Then terminate any remaining detached processes.
      pkill -TERM -x quickshell 2>/dev/null || true

      # Wait briefly for a clean shutdown.
      for _ in $(seq 1 30); do
        if ! pgrep -x quickshell >/dev/null 2>&1; then
          return
        fi
        sleep 0.1
      done

      # Last resort if a stale process is stuck.
      pkill -KILL -x quickshell 2>/dev/null || true
    }

    repo_root="''${DOTFILES:-}"
    if [ -z "$repo_root" ]; then
      repo_root="$HOME/Sources/dotfiles"
    fi

    if [ "$mode" = "dev" ] && [ ! -f "$repo_root/modules/programs/quickshell/ui/shell.qml" ]; then
      if command -v git >/dev/null 2>&1; then
        guessed_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [ -n "$guessed_root" ] && [ -f "$guessed_root/modules/programs/quickshell/ui/shell.qml" ]; then
          repo_root="$guessed_root"
        fi
      fi
    fi

    stop_quickshell

    if [ "$mode" = "dev" ]; then
      config_args=(--path "$repo_root/modules/programs/quickshell/ui")
      qml_import_path="$repo_root/modules/programs/quickshell/ui:$repo_root/modules/programs/quickshell/ui/components:$repo_root/modules/programs/quickshell/ui/services:$repo_root/modules/programs/quickshell/ui/modules/bar"
    else
      config_args=(--config default)
      config_root="$HOME/.config/quickshell"
      qml_import_path="$config_root:$config_root/components:$config_root/services:$config_root/modules/bar"
    fi

    dev_args=(--path "$repo_root/modules/programs/quickshell/ui")

    run_quickshell() {
      env \
        DOTFILES="$repo_root" \
        QML2_IMPORT_PATH="$qml_import_path" \
        QML_XHR_ALLOW_FILE_READ=1 \
        quickshell --no-duplicate "$@"
    }

    run_quickshell_background() {
      if command -v uwsm >/dev/null 2>&1; then
        uwsm app -- env \
          DOTFILES="$repo_root" \
          QML2_IMPORT_PATH="$qml_import_path" \
          QML_XHR_ALLOW_FILE_READ=1 \
          quickshell --no-duplicate "$@" >/dev/null 2>&1 &
      else
        env \
          DOTFILES="$repo_root" \
          QML2_IMPORT_PATH="$qml_import_path" \
          QML_XHR_ALLOW_FILE_READ=1 \
          quickshell --no-duplicate "$@" >/dev/null 2>&1 &
      fi
    }

    if [ "$foreground" = "1" ]; then
      if [ "$mode" = "prod" ]; then
        set +e
        run_quickshell "''${config_args[@]}"
        prod_status=$?
        set -e

        if [ "$prod_status" -ne 0 ]; then
          if [ ! -f "$repo_root/modules/programs/quickshell/ui/shell.qml" ]; then
            echo "reload-bar: prod failed and dev fallback path is unavailable: $repo_root/modules/programs/quickshell/ui/shell.qml" >&2
            exit "$prod_status"
          fi
          echo "reload-bar: prod startup failed, falling back to --dev" >&2
          run_quickshell "''${dev_args[@]}"
          exit $?
        fi

        exit 0
      fi

      run_quickshell "''${config_args[@]}"
      exit $?
    fi

    run_quickshell_background "''${config_args[@]}"

    # In default prod mode, attempt an automatic dev fallback if quickshell
    # failed to come up (for example stale installed config after local edits).
    if [ "$mode" = "prod" ]; then
      for _ in $(seq 1 20); do
        if pgrep -x quickshell >/dev/null 2>&1; then
          exit 0
        fi
        sleep 0.1
      done

      if [ ! -f "$repo_root/modules/programs/quickshell/ui/shell.qml" ]; then
        echo "reload-bar: prod startup failed and dev fallback path is unavailable: $repo_root/modules/programs/quickshell/ui/shell.qml" >&2
        exit 1
      fi

      echo "reload-bar: prod startup failed, falling back to --dev" >&2
      stop_quickshell
      run_quickshell_background "''${dev_args[@]}"
    fi
''
