# Read-only CLI consumers of the active rice (D-042). rice-query is the
# generic data adapter for shell tools; rice-terminal renders the
# theme-configured terminal greeting and command-not-found line from
# `widgets.terminal.settings`. Neither writes state: PrefsState stays the
# sole writer of prefs.json and rice-switch the sole writer of the pointer.
{ pkgs }:
let
  activeManifestLib = import ./_active-manifest-lib.nix { inherit pkgs; };

  # Shared prologue: environment overrides mirror rice-hyprland-theme so the
  # same flake check fixtures drive both programs.
  prologue = name: ''
    set -euo pipefail

    jq="''${RICE_JQ:-${pkgs.jq}/bin/jq}"
    index="''${RICE_INDEX:-$HOME/.config/rice/themes.json}"
    state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/rice"
    pointer="$state_dir/active"
    prefs_file="$state_dir/prefs.json"
    active_theme=""
    manifest=""

    fail() {
      echo "${name}: $*" >&2
      exit 2
    }

    ${activeManifestLib}

    resolve_manifest() {
      rice_resolve_active
      manifest="$(canonical_store_file "theme manifest" "$manifest")"
    }
  '';

  riceQuery = pkgs.writeShellScriptBin "rice-query" ''
    ${prologue "rice-query"}

    usage() {
      cat <<'EOF'
    Usage: rice-query [--json] <command>

      active          name of the active theme
      manifest        store path of the active theme's manifest
      get <path>      value at a dotted path in the active manifest
      pref <path>     value at a dotted path in prefs.json (read-only)

    Paths are dot-separated keys; numeric segments index arrays
    (e.g. widgets.tarotDraw.settings.cards.0.name). Strings print raw unless
    --json is given; other values print as compact JSON.

    Exit status: 0 found, 1 not set (missing or null), 2 usage or data error.
    EOF
    }

    json=0
    while [ "$#" -gt 0 ]; do
      case "$1" in
        --json) json=1; shift ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) usage >&2; exit 2 ;;
        *) break ;;
      esac
    done
    [ "$#" -ge 1 ] || { usage >&2; exit 2; }

    lookup() {
      local path="$1"
      local file="$2"
      case "$path" in
        ""|.*|*.|*..*) fail "invalid path: $path" ;;
      esac
      local status=0
      "$jq" -e --arg path "$path" --argjson json "$json" '
        getpath($path | split(".") | map(if test("^[0-9]+$") then tonumber else . end))
        | if . == null then empty
          elif ($json == 0 and type == "string") then .
          else tojson end
      ' -r "$file" || status=$?
      # jq -e: 1 = last output null/false (unset), 4 = no output (unset), other = error.
      case "$status" in
        0) ;;
        1|4) exit 1 ;;
        *) fail "could not read $path from $file" ;;
      esac
    }

    command="$1"; shift
    case "$command" in
      active)
        [ "$#" -eq 0 ] || fail "active takes no arguments"
        rice_resolve_active
        if [ "$json" -eq 1 ]; then "$jq" -n --arg name "$active_theme" '$name'; else printf '%s\n' "$active_theme"; fi ;;
      manifest)
        [ "$#" -eq 0 ] || fail "manifest takes no arguments"
        resolve_manifest
        printf '%s\n' "$manifest" ;;
      get)
        [ "$#" -eq 1 ] || fail "get takes exactly one path"
        resolve_manifest
        lookup "$1" "$manifest" ;;
      pref)
        [ "$#" -eq 1 ] || fail "pref takes exactly one path"
        [ -e "$prefs_file" ] || exit 1
        lookup "$1" "$prefs_file" ;;
      *)
        usage >&2; exit 2 ;;
    esac
  '';

  # Placeholders `{field}` in a format string are replaced from an object;
  # unknown fields render empty. Colour comes from the manifest's primary
  # accent and is skipped when NO_COLOR is set or stdout is not a terminal.
  riceTerminal = pkgs.writeShellScriptBin "rice-terminal" ''
    ${prologue "rice-terminal"}

    usage() {
      echo "Usage: rice-terminal (greeting | command-not-found <command>)"
    }

    quickshell="''${RICE_QUICKSHELL:-${pkgs.quickshell}/bin/quickshell}"
    color=1
    [ -t 1 ] && [ -z "''${NO_COLOR:-}" ] || color=0

    render() {
      local filter="$1"; shift
      local status=0
      "$jq" -er --argjson color "$color" "$@" '
        def segments: split(".") | map(if test("^[0-9]+$") then tonumber else . end);
        def fill($fields): gsub("\\{(?<k>[A-Za-z0-9_]+)\\}"; ($fields[.k] // "" | tostring));
        def hexbyte: ascii_downcase | explode | reduce .[] as $c (0; . * 16 + (if $c >= 97 then $c - 87 else $c - 48 end));
        def paint: (.tokens.colors.accent.primary? // "") as $accent |
          if $color == 1 and ($accent | type == "string" and test("^#[0-9a-fA-F]{6}$"))
          then "\u001b[38;2;" + ([$accent[1:3], $accent[3:5], $accent[5:7]] | map(hexbyte | tostring) | join(";")) + "m"
          else "" end;
        . as $manifest | (.widgets.terminal.settings // {}) as $settings |
        '"$filter" "$manifest" || status=$?
      case "$status" in
        0) ;;
        1|4) exit 1 ;;
        *) fail "could not render from $manifest" ;;
      esac
    }

    [ "$#" -ge 1 ] || { usage >&2; exit 2; }
    command="$1"; shift
    case "$command" in
      greeting)
        [ "$#" -eq 0 ] || fail "greeting takes no arguments"
        resolve_manifest
        # Prefs are parsed inside the filter, after the theme is known to
        # configure a greeting, so unconfigured themes never touch them.
        prefs_source=/dev/null
        [ ! -r "$prefs_file" ] || prefs_source="$prefs_file"
        today="$(${pkgs.coreutils}/bin/date +%F)"
        # Daily record ({date, id?, index?}) from prefs (or an IPC-confirmed
        # override), resolved against a manifest catalog by id, then by
        # position. Emits `line<TAB>text`, or `draw<TAB>ns<TAB>key<TAB>json`
        # when autoDraw may claim today's record under extras.<ns>.<key>.
        greeting_pass() {
          render '
            def painted($line): paint as $on | $on + $line + (if $on == "" then "" else "\u001b[0m" end);
            ($settings.greeting.daily // empty) as $daily |
            (if $override != null then $override
             else ($prefs_raw | if test("^\\s*$") then {} else fromjson end
               | getpath($daily.record | segments)) end) as $record |
            ($manifest | getpath($daily.catalog | segments) // []) as $catalog |
            (if ($record | type) == "object" and $record.date == $today then
              (if $record.id != null then ([$catalog[] | select(.id == $record.id)] | first) else null end)
              // (($record.index // $record.card) as $i
                  | if ($i | type) == "number" and $i >= 0 and $i < ($catalog | length) then $catalog[$i] else null end)
            else null end) as $entry |
            ($daily.record | segments) as $path |
            if $entry != null then "line\t" + painted(($daily.format // "{name}") | fill($entry))
            elif $allowDraw == 1 and $daily.autoDraw == true and ($catalog | length) > 0
              and ($path | length) == 3 and $path[0] == "extras" then
              ($seed % ($catalog | length)) as $i |
              "draw\t\($path[1])\t\($path[2])\t"
                + ({date: $today, id: $catalog[$i].id, index: $i} | with_entries(select(.value != null)) | tojson)
            else "line\t" + painted($daily.pendingLabel // empty) end
          ' --rawfile prefs_raw "$prefs_source" --arg today "$today" \
            --argjson override "$1" --argjson allowDraw "$2" --argjson seed "$RANDOM"
        }
        out="$(greeting_pass null 1)"
        if [[ "$out" == draw$'\t'* ]]; then
          # PrefsState is the sole prefs writer: ask the running shell to
          # claim the record (first writer per day wins). Without a shell
          # the greeting falls back to the pending label.
          IFS=$'\t' read -r _ claim_ns claim_key claim_record <<< "$out"
          effective="$(${pkgs.coreutils}/bin/timeout 2 "$quickshell" -c rice ipc call prefs claimDaily \
            "$claim_ns" "$claim_key" "$claim_record" 2>/dev/null)" || effective=""
          "$jq" -e 'type == "object"' <<< "$effective" > /dev/null 2>&1 || effective=null
          out="$(greeting_pass "$effective" 0)"
        fi
        printf '%s\n' "''${out#line$'\t'}" ;;
      command-not-found)
        [ "$#" -eq 1 ] || fail "command-not-found takes exactly one command"
        resolve_manifest
        render '
          ($settings.commandNotFound.format // empty) | fill({command: $command})
        ' --arg command "$1" ;;
      -h|--help)
        usage ;;
      *)
        usage >&2; exit 2 ;;
    esac
  '';
in
{
  inherit riceQuery riceTerminal;
}
