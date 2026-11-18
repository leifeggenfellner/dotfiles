#!/usr/bin/env bash
# Renders every cue whose recipe lives here (sealed-letter.wav and
# red-seal.wav predate the recipes and set the loudness target).
# Usage: nix shell nixpkgs#sox -c ./render-all.sh
set -euo pipefail
cd "$(dirname "$0")"
for recipe in *.sh; do
    if [ "$recipe" != lib.sh ] && [ "$recipe" != render-all.sh ]; then
        bash "$recipe"
    fi
done
