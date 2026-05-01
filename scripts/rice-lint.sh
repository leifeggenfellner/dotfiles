#!/usr/bin/env bash
# rice-lint — mechanical enforcement of the rice runtime contracts (D-015).
#
# Checks, per docs/architecture/ARCHITECTURE.md "Import rules":
#   1. Relative QML imports respect the layer DAG:
#        utils      → (nothing)
#        core       → utils
#        components → core, utils
#        widgets    → components, core, utils
#        services   → utils (and only its OWN domain dir)
#        modules    → everything below it
#        shell.qml  → modules, core
#   2. No theme-name literals anywhere under the runtime (D-006).
#
# Usage: rice-lint.sh [runtime-root]   (default: modules/rice/runtime/quickshell)
set -euo pipefail

root="${1:-modules/rice/runtime/quickshell}"
root="$(realpath "$root")"
fail=0

layer_allow() {
  case "$1" in
    utils) echo "" ;;
    core) echo "utils" ;;
    components) echo "core utils" ;;
    widgets) echo "components core utils" ;;
    services) echo "utils" ;;
    modules) echo "modules widgets components core utils services" ;;
    .) echo "modules core" ;;
    *) echo "" ;;
  esac
}

while IFS= read -r -d '' file; do
  rel="${file#"$root"/}"
  if [[ "$rel" == */* ]]; then
    src_layer="${rel%%/*}"
  else
    src_layer="."
  fi
  src_dir="$(dirname "$file")"

  while IFS= read -r imp; do
    tgt="$(realpath -m "$src_dir/$imp")"
    [[ "$tgt" == "$root"* ]] || {
      echo "VIOLATION: $rel imports outside the runtime: $imp"
      fail=1
      continue
    }
    trel="${tgt#"$root"}"
    trel="${trel#/}"
    if [[ -z "$trel" ]]; then
      tgt_layer="."
    else
      tgt_layer="${trel%%/*}"
    fi

    if [[ "$tgt_layer" == "$src_layer" ]]; then
      # Same layer is fine — except services, which may not import
      # other service domains (service-contract.md).
      if [[ "$src_layer" == "services" ]]; then
        src_domain="$(cut -d/ -f2 <<<"$rel")"
        tgt_domain="$(cut -d/ -f2 <<<"$trel")"
        if [[ "$src_domain" != "$tgt_domain" ]]; then
          echo "VIOLATION: $rel (service:$src_domain) imports service domain '$tgt_domain'"
          fail=1
        fi
      fi
      continue
    fi

    allowed=" $(layer_allow "$src_layer") "
    if [[ "$allowed" != *" $tgt_layer "* ]]; then
      echo "VIOLATION: $rel (layer:$src_layer) imports '$imp' (layer:$tgt_layer)"
      fail=1
    fi
  done < <(grep -oE '^import "[^"]+"' "$file" | sed 's/^import "//; s/"$//' || true)
done < <(find "$root" -name '*.qml' -print0)

# Theme-name literal ban (D-006). Case-insensitive, word-ish match.
if literals=$(grep -rinE '\blotm\b|\bpokemon\b|pathway' "$root" 2>/dev/null); then
  echo "VIOLATION: theme literals in runtime:"
  echo "$literals"
  fail=1
fi

if [[ "$fail" -ne 0 ]]; then
  echo "rice-lint: FAILED"
  exit 1
fi
echo "rice-lint: OK ($root)"
