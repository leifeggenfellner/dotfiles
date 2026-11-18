#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# launcher-open: a summoning shimmer, rising and settling.
. "$(dirname "$0")/lib.sh"
gen "$tmp/rise.wav" synth 0.42 sine 330-990 sine 495-1485 tremolo 14 40 fade h 0.05 0.42 0.25 vol 0.4
gen "$tmp/air.wav" synth 0.42 pinknoise sinc 3000-9000 fade h 0.1 0.42 0.3 vol 0.08
sox -m "$tmp/rise.wav" "$tmp/air.wav" "$tmp/mix.wav" reverb 40 50 60 pad 0 0.15
finish launcher-open.wav -2 "$tmp/mix.wav"
