#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# satchel-seal: a clasp shutting on the satchel, a click over a small thud.
. "$(dirname "$0")/lib.sh"
gen "$tmp/thud.wav" synth 0.14 sine 180-120 fade p 0.002 0.14 0.12 vol 0.6
gen "$tmp/click.wav" synth 0.14 sine 2600 fade p 0.001 0.14 0.135 vol 0.25
sox -m "$tmp/thud.wav" "$tmp/click.wav" "$tmp/mix.wav"
finish satchel-seal.wav -2 "$tmp/mix.wav"
