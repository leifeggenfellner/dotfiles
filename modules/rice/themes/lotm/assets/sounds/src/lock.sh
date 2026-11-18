#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# lock: a wax seal pressed home, a low thump under a short press.
. "$(dirname "$0")/lib.sh"
gen "$tmp/thump.wav" synth 0.22 sine 110-70 fade p 0.002 0.22 0.2 vol 0.7
gen "$tmp/press.wav" synth 0.22 brownnoise sinc 200-1600 fade q 0.004 0.22 0.19 vol 0.3
sox -m "$tmp/thump.wav" "$tmp/press.wav" "$tmp/mix.wav"
finish lock.wav 0 "$tmp/mix.wav"
