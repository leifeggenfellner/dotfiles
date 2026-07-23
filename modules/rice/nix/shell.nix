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
        pkgs.qt6.qt5compat
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

      # Nix-store copy of the LOTM lockscreen theme assets. Selected
      # by rice-lock-screen when --variant lotm, RICE_LOCK_VARIANT=lotm,
      # or the active theme manifest declares assets.lockscreenVariant = "lotm".
      lotm-lockscreen-theme = pkgs.runCommand "rice-lockscreen-lotm" { } ''
        cp -r ${../themes/lotm/lockscreen/lotm} "$out"
      '';

      rice-lock-screen = pkgs.writeShellScriptBin "rice-lock-screen" ''
        set -euo pipefail

        mode="prod"
        preview="0"
        dry_run="0"
        # Track whether variant was explicitly set (CLI/env) so the
        # manifest's assets.lockscreenVariant only wins as a fallback.
        if [ -n "''${RICE_LOCK_VARIANT:-}" ]; then
          variant="$RICE_LOCK_VARIANT"
          variant_explicit=1
        else
          variant="default"
          variant_explicit=0
        fi
        JQ=${pkgs.jq}/bin/jq

        while [ "$#" -gt 0 ]; do
          case "$1" in
            --dev) mode="dev" ;;
            --prod) mode="prod" ;;
            --preview) preview="1" ;;
            --dry-run|--print-root) dry_run="1" ;;
            --variant)
              shift
              [ "$#" -gt 0 ] || { echo "rice-lock-screen: --variant needs a value" >&2; exit 64; }
              variant="$1"; variant_explicit=1 ;;
            --variant=*) variant="''${1#--variant=}"; variant_explicit=1 ;;
            -h|--help)
              cat <<'USAGE'
        Usage: rice-lock-screen [--dev|--prod] [--preview] [--dry-run] [--variant default|lotm]

          --prod       Run the installed ~/.config/quickshell/rice/lock.qml root.
          --dev        Run lock.qml directly from the dotfiles checkout.
          --preview    Render the LOTM lockscreen in a normal window. This never
                       takes WlSessionLock and suppresses login/reboot/poweroff.
          --dry-run    Print resolved mode, variant, root and LOTM lockscreen theme path,
                       then exit without starting Quickshell.
          --variant V  Choose lock UI variant: default (rice-native recovery) | lotm.
                       Also honours RICE_LOCK_VARIANT.

        Variant resolution order (first wins):
          1. --variant CLI flag
          2. RICE_LOCK_VARIANT env var
          3. active theme manifest's assets.lockscreenVariant
          4. "default"

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
        export QML_XHR_ALLOW_FILE_READ=1

        INDEX="$HOME/.config/rice/themes.json"
        POINTER="''${XDG_STATE_HOME:-$HOME/.local/state}/rice/active"
        MANIFEST=""
        if [ -r "$INDEX" ]; then
          theme_name=""
          [ -r "$POINTER" ] && theme_name=$(cat "$POINTER")
          if [ -z "$theme_name" ] || ! $JQ -e --arg n "$theme_name" '.themes[$n]' "$INDEX" >/dev/null 2>&1; then
            theme_name=$($JQ -r '.default // empty' "$INDEX")
          fi
          [ -n "$theme_name" ] && MANIFEST=$($JQ -r --arg n "$theme_name" '.themes[$n].manifest // empty' "$INDEX")
          [ -r "$MANIFEST" ] || MANIFEST=""
        fi

        if [ -n "$MANIFEST" ]; then
          lock_image=$($JQ -r '((.assets.wallpapers // []) | map(select(endswith("/klein_airships.png") or endswith("/klein_airships.jpg") or endswith("/klein_airships.jpeg") or endswith("/klein_airships.webp"))) | .[0]) // (.assets.lockscreen[0] // empty)' "$MANIFEST")
          lock_video=$($JQ -r '((.assets.lockscreenVideos // []) | map(select(endswith("/klein_loen.mp4"))) | .[0]) // empty' "$MANIFEST")
          accent=$($JQ -r '.tokens.colors.accent.primary // empty' "$MANIFEST")
          font=$($JQ -r '.tokens.typography.families.display // empty' "$MANIFEST")

          # Manifest-declared variant, honoured only when CLI/env didn't force one.
          if [ "$variant_explicit" = "0" ]; then
            manifest_variant=$($JQ -r '.assets.lockscreenVariant // empty' "$MANIFEST")
            if [ -n "$manifest_variant" ]; then
              variant="$manifest_variant"
            fi
          fi

          if [ -z "''${RICE_LOCK_IMAGE:-}" ] && [ -n "$lock_image" ] && [ -f "$lock_image" ]; then
            export RICE_LOCK_IMAGE="$lock_image"
          fi
          if [ -z "''${RICE_LOCK_VIDEO:-}" ] && [ -n "$lock_video" ] && [ -f "$lock_video" ]; then
            export RICE_LOCK_VIDEO="$lock_video"
          fi
          if [ -z "''${RICE_LOCK_MODE:-}" ]; then
            if [ -n "''${RICE_LOCK_VIDEO:-}" ]; then
              export RICE_LOCK_MODE="video"
            else
              export RICE_LOCK_MODE="image"
            fi
          fi
          if [ -z "''${RICE_LOCK_ACCENT:-}" ] && [ -n "$accent" ]; then
            export RICE_LOCK_ACCENT="$accent"
          fi
          if [ -z "''${RICE_LOCK_FONT:-}" ] && [ -n "$font" ]; then
            export RICE_LOCK_FONT="$font"
          fi
        fi

        if [ "$preview" = "1" ] && [ "$variant" = "default" ] && [ "$variant_explicit" = "0" ]; then
          variant="lotm"
        fi

        case "$variant" in
          default)
            if [ "$preview" = "1" ]; then
              echo "rice-lock-screen: --preview currently supports only --variant lotm" >&2
              exit 64
            fi
            lock_file="lock.qml" ;;
          lotm)
            if [ "$preview" = "1" ]; then
              lock_file="preview-theme.qml"
            else
              lock_file="lock-theme.qml"
            fi
            export RICE_LOCK_LOTM_THEME_PATH="${lotm-lockscreen-theme}"
            export RICE_LOCK_THEME_PATH="$RICE_LOCK_LOTM_THEME_PATH"
            [ -z "''${RICE_LOCK_CHIME:-}" ] && [ -n "''${RICE_LOTM_LOCK_CHIME:-}" ] && export RICE_LOCK_CHIME="$RICE_LOTM_LOCK_CHIME"
            # Export theme-driven colours for the LOTM lockscreen. Main.qml
            # falls back to its native LOTM literals when
            # these are unset, so unmanifested themes still look right.
            if [ -n "$MANIFEST" ]; then
              lotm_lock_fg=$($JQ -r '.tokens.colors.fg.primary // empty' "$MANIFEST")
              lotm_lock_accent=$($JQ -r '.tokens.colors.accent.primary // empty' "$MANIFEST")
              lotm_lock_accent_dim=$($JQ -r '.tokens.colors.fg.muted // empty' "$MANIFEST")
              lotm_lock_orbit=$($JQ -r '.tokens.colors.accent.secondary // empty' "$MANIFEST")
              lotm_lock_unlock_sound=$($JQ -r '.assets.sounds.notification // empty' "$MANIFEST")
              [ -z "''${RICE_LOTM_LOCK_FG:-}"         ] && [ -n "$lotm_lock_fg" ]         && export RICE_LOTM_LOCK_FG="$lotm_lock_fg"
              [ -z "''${RICE_LOTM_LOCK_ACCENT:-}"     ] && [ -n "$lotm_lock_accent" ]     && export RICE_LOTM_LOCK_ACCENT="$lotm_lock_accent"
              [ -z "''${RICE_LOTM_LOCK_ACCENT_DIM:-}" ] && [ -n "$lotm_lock_accent_dim" ] && export RICE_LOTM_LOCK_ACCENT_DIM="$lotm_lock_accent_dim"
              [ -z "''${RICE_LOTM_LOCK_ORBIT:-}"      ] && [ -n "$lotm_lock_orbit" ]      && export RICE_LOTM_LOCK_ORBIT="$lotm_lock_orbit"
              if [ -z "''${RICE_LOTM_LOCK_UNLOCK_SOUND:-}" ] && [ -n "$lotm_lock_unlock_sound" ] && [ -f "$lotm_lock_unlock_sound" ]; then
                export RICE_LOTM_LOCK_UNLOCK_SOUND="$lotm_lock_unlock_sound"
              fi
              [ -z "''${RICE_LOCK_UNLOCK_SOUND:-}" ] && [ -n "''${RICE_LOTM_LOCK_UNLOCK_SOUND:-}" ] && export RICE_LOCK_UNLOCK_SOUND="$RICE_LOTM_LOCK_UNLOCK_SOUND"
            fi
            ;;
          *) echo "rice-lock-screen: unknown variant: $variant" >&2; exit 64 ;;
        esac

        if [ "$mode" = "dev" ]; then
          repo_root="''${DOTFILES:-$HOME/Sources/dotfiles}"
          lock_root="$repo_root/modules/rice/runtime/quickshell/$lock_file"
          # Dev mode: point at in-tree assets so hot edits work.
          if [ "$variant" = "lotm" ]; then
            export RICE_LOCK_LOTM_THEME_PATH="$repo_root/modules/rice/themes/lotm/lockscreen/lotm"
            export RICE_LOCK_THEME_PATH="$RICE_LOCK_LOTM_THEME_PATH"
            [ -z "''${RICE_LOCK_CHIME:-}" ] && [ -n "''${RICE_LOTM_LOCK_CHIME:-}" ] && export RICE_LOCK_CHIME="$RICE_LOTM_LOCK_CHIME"
          fi
        else
          lock_root="$HOME/.config/quickshell/rice/$lock_file"
        fi

        if [ "$dry_run" = "1" ]; then
          printf 'mode=%s\n' "$mode"
          printf 'preview=%s\n' "$preview"
          printf 'variant=%s\n' "$variant"
          printf 'lock_file=%s\n' "$lock_file"
          printf 'lock_root=%s\n' "$lock_root"
          printf 'RICE_LOCK_LOTM_THEME_PATH=%s\n' "''${RICE_LOCK_LOTM_THEME_PATH:-}"
          exit 0
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
