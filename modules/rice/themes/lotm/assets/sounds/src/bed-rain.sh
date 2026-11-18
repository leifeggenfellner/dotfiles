#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# bed-rain: Backlund rain on slate roofs, a soft wash that swells and
# eases, scattered drops over it and a low gutter murmur under it.
. "$(dirname "$0")/lib.sh"
gen "$tmp/wash.wav" synth 36 pinknoise sinc 400-7000 lowpass 4500 tremolo 0.13 25 vol 0.5
impulses "$tmp/drops-raw.wav" 36 140 7
sox "$tmp/drops-raw.wav" "$tmp/drops.wav" sinc 1200-6000 reverb 30 50 40 vol 1.2
gen "$tmp/murmur.wav" synth 36 brownnoise lowpass 300 tremolo 0.07 30 vol 0.4
sox -m -v 0.4 "$tmp/wash.wav" -v 0.4 "$tmp/drops.wav" -v 0.4 "$tmp/murmur.wav" "$tmp/rain.wav"
loop "$tmp/rain.wav" "$tmp/rain-loop.wav" 32 4
finish bed-rain.ogg -8 "$tmp/rain-loop.wav"
