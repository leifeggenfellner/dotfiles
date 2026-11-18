#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# bed-fog: above the gray fog, a wind with no source and a deep, slowly
# beating drone, a faint high shimmer over the castle's quiet.
. "$(dirname "$0")/lib.sh"
gen "$tmp/wind.wav" synth 45 brownnoise sinc 150-900 tremolo 0.07 60 vol 0.6
gen "$tmp/whistle.wav" synth 45 pinknoise sinc 1500-3000 tremolo 0.11 70 vol 0.12
gen "$tmp/drone-a.wav" synth 45 sine 55 tremolo 0.05 40 vol 0.25
gen "$tmp/drone-b.wav" synth 45 sine 82.5 tremolo 0.035 50 vol 0.18
gen "$tmp/drone-c.wav" synth 45 sine 110.6 vol 0.12
gen "$tmp/shimmer.wav" synth 45 sine 880 tremolo 0.2 80 vol 0.015
sox -m -v 1 "$tmp/wind.wav" -v 1 "$tmp/whistle.wav" -v 1 "$tmp/drone-a.wav" -v 1 "$tmp/drone-b.wav" \
    -v 1 "$tmp/drone-c.wav" -v 1 "$tmp/shimmer.wav" "$tmp/fog.wav" vol 0.4 reverb 60
loop "$tmp/fog.wav" "$tmp/fog-loop.wav" 40 5
finish bed-fog.ogg -10 "$tmp/fog-loop.wav"
