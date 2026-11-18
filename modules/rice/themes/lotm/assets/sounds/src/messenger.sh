#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# messenger (D-056): a paper flutter, then two soft knocks.
. "$(dirname "$0")/lib.sh"
gen "$tmp/flutter.wav" synth 0.18 pinknoise sinc 1800-5200 tremolo 38 90 fade q 0.02 0.18 0.1 vol 0.35
gen "$tmp/tap.wav" synth 0.06 sine 520 sine 780 fade q 0.002 0.06 0.05 vol 0.5
gen "$tmp/gap.wav" trim 0 0.07
finish messenger.wav -3 "$tmp/flutter.wav" "$tmp/tap.wav" "$tmp/gap.wav" "$tmp/tap.wav"
