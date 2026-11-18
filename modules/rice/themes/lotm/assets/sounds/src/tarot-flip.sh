#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# tarot-flip: a card flicked over, a quick swish and its landing.
. "$(dirname "$0")/lib.sh"
gen "$tmp/swish.wav" synth 0.09 whitenoise sinc 2500-8000 fade h 0.03 0.09 0.05 vol 0.35
gen "$tmp/land.wav" synth 0.05 pinknoise sinc 600-3000 fade p 0.001 0.05 0.045 vol 0.5
finish tarot-flip.wav -3 "$tmp/swish.wav" "$tmp/land.wav"
