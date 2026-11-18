#!/usr/bin/env bash
# Renders messenger.wav (D-056): a paper flutter, then two soft knocks.
# Usage: nix shell nixpkgs#sox -c ./messenger.sh
set -euo pipefail
cd "$(dirname "$0")"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

sox -n -r 44100 -c 1 -b 16 "$tmp/flutter.wav" synth 0.18 pinknoise sinc 1800-5200 tremolo 38 90 fade q 0.02 0.18 0.1 vol 0.35
sox -n -r 44100 -c 1 -b 16 "$tmp/tap.wav" synth 0.06 sine 520 sine 780 fade q 0.002 0.06 0.05 vol 0.5
sox -n -r 44100 -c 1 -b 16 "$tmp/gap.wav" trim 0 0.07
# Peak level matched to sealed-letter.wav and red-seal.wav.
sox "$tmp/flutter.wav" "$tmp/tap.wav" "$tmp/gap.wav" "$tmp/tap.wav" -b 16 messenger.wav norm -12.5
