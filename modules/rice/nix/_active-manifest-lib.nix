# Shell functions shared by the read-only active-theme consumers
# (rice-hyprland-theme, rice-query): resolve the theme index and the
# $XDG_STATE_HOME/rice/active pointer to an immutable manifest store file.
# The caller defines `fail` and the variables `jq`, `index`, and `pointer`;
# `rice_resolve_active` sets `active_theme` and `manifest`. rice-switch keeps
# its own stricter transactional validation (D-040).
{ pkgs }:
''
  canonical_store_file() {
    local description="$1"
    local candidate="$2"
    local canonical
    canonical="$(${pkgs.coreutils}/bin/realpath -e -- "$candidate")" || fail "$description does not resolve: $candidate"
    case "$canonical" in
      /nix/store/*) ;;
      *) fail "$description must resolve to /nix/store: $candidate" ;;
    esac
    [ -f "$canonical" ] || fail "$description must resolve to a regular file: $candidate"
    printf '%s' "$canonical"
  }

  rice_resolve_active() {
    index="$(canonical_store_file "theme index" "$index")"
    local selected=""
    [ ! -r "$pointer" ] || selected="$(cat "$pointer")"
    local resolved
    resolved="$("$jq" -er --arg selected "$selected" '
      select(
        .schemaVersion == 1 and
        (.default | type == "string") and
        (.themes | type == "object") and
        (.themes[.default].manifest | type == "string")
      ) |
      (if ($selected != "" and (.themes[$selected].manifest | type == "string"))
        then $selected else .default end) as $name |
      [$name, .themes[$name].manifest] | @tsv
    ' "$index")" || fail "invalid theme index at $index"
    # shellcheck disable=SC2034 # active_theme is read by the including program.
    IFS=$'\t' read -r active_theme manifest <<< "$resolved"
  }
''
