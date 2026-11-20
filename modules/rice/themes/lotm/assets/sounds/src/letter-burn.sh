#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# letter-burn: a letter catching and burning away (D-082): a soft roar as
# the paper takes, a bright hiss of the edge, and sparse crackles, all
# dying out over the burn.
. "$(dirname "$0")/lib.sh"
gen "$tmp/roar.wav" synth 1.7 brownnoise lowpass 700 fade q 0.18 1.7 1.1 vol 0.55
gen "$tmp/hiss.wav" synth 1.7 pinknoise sinc 2200-7000 fade q 0.06 1.7 1.35 vol 0.14
impulses "$tmp/crackle-raw.wav" 1.7 38 11
sox "$tmp/crackle-raw.wav" "$tmp/crackle.wav" sinc 900-6000 fade q 0.08 1.7 0.9 vol 1.4
sox -m -v 0.6 "$tmp/roar.wav" -v 0.5 "$tmp/hiss.wav" -v 0.6 "$tmp/crackle.wav" "$tmp/mix.wav" reverb 20 50 40
finish letter-burn.wav -5 "$tmp/mix.wav"
