#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# bed-crackle: a gramophone between records, the needle in the run-out
# groove: surface hiss, fine dust and the odd crackle, turning at 78 rpm.
. "$(dirname "$0")/lib.sh"
gen "$tmp/hiss.wav" synth 23 pinknoise sinc 1500-8000 vol 0.12
impulses "$tmp/dust-raw.wav" 23 300 5
sox "$tmp/dust-raw.wav" "$tmp/dust.wav" sinc 3000-9000 vol 0.6
impulses "$tmp/crackle-raw.wav" 23 20 3
sox "$tmp/crackle-raw.wav" "$tmp/crackle.wav" sinc 700-5000 tremolo 1.3 40 vol 1.2
sox -m -v 0.4 "$tmp/hiss.wav" -v 0.4 "$tmp/dust.wav" -v 0.4 "$tmp/crackle.wav" "$tmp/record.wav" lowpass 6000
loop "$tmp/record.wav" "$tmp/record-loop.wav" 20 3
finish bed-crackle.ogg -14 "$tmp/record-loop.wav"
