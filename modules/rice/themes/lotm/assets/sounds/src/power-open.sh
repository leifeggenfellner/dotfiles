#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# power-open: the ritual's low bell, inharmonic partials decaying.
. "$(dirname "$0")/lib.sh"
gen "$tmp/bell.wav" synth 0.9 sine 147 sine 405 sine 589 fade p 0.003 0.9 0.85 vol 0.45
sox "$tmp/bell.wav" "$tmp/wet.wav" reverb 55 50 80 pad 0 0.1 trim 0 0.95
finish power-open.wav -1 "$tmp/wet.wav"
