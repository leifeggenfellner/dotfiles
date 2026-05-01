{ pkgs }:

pkgs.writeShellScriptBin "kill-bar-dev" ''
  set -euo pipefail

  repo_root="''${DOTFILES:-}"
  if [ -z "$repo_root" ]; then
    repo_root="$HOME/Sources/dotfiles"
  fi

  dev_path="$repo_root/modules/programs/quickshell/ui"

  # Kill the exact dev-path instance first.
  quickshell kill --path "$dev_path" >/dev/null 2>&1 || true

  # Fallback: terminate any lingering quickshell process launched with the dev path.
  pkill -TERM -f "quickshell --no-duplicate --path $dev_path" 2>/dev/null || true

  for _ in $(seq 1 30); do
    if ! pgrep -f "quickshell --no-duplicate --path $dev_path" >/dev/null 2>&1; then
      echo "kill-bar-dev: stopped dev bar ($dev_path)"
      exit 0
    fi
    sleep 0.1
  done

  pkill -KILL -f "quickshell --no-duplicate --path $dev_path" 2>/dev/null || true

  if pgrep -f "quickshell --no-duplicate --path $dev_path" >/dev/null 2>&1; then
    echo "kill-bar-dev: failed to stop dev bar ($dev_path)" >&2
    exit 1
  fi

  echo "kill-bar-dev: stopped dev bar ($dev_path)"
''
