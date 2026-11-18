#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# unlock: a key turning twice, then the seal giving with a soft chime.
. "$(dirname "$0")/lib.sh"
gen "$tmp/click1.wav" synth 0.03 sine 1900 sine 3100 fade p 0.001 0.03 0.028 vol 0.5
gen "$tmp/click2.wav" synth 0.03 sine 2300 sine 3600 fade p 0.001 0.03 0.028 vol 0.5
gen "$tmp/gap.wav" trim 0 0.06
gen "$tmp/chime.wav" synth 0.4 sine 660 sine 990 fade p 0.005 0.4 0.37 vol 0.35
finish unlock.wav -1 "$tmp/click1.wav" "$tmp/gap.wav" "$tmp/click2.wav" "$tmp/gap.wav" "$tmp/chime.wav"
