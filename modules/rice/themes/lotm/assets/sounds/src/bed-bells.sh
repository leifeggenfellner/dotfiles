#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# bed-bells: a church bell across the city tolls three times, then a
# long quiet. Partials after a tuned bell (hum, prime, minor-third
# tierce, quint, nominal); distance takes the top off and adds the
# streets' echo. Silent at both ends, so it loops as it is.
. "$(dirname "$0")/lib.sh"
f=196
partial() { gen "$tmp/p$1.wav" synth "$3" sine "$(awk -v f="$f" -v r="$1" 'BEGIN { print f * r }')" fade l 0.004 "$3" "$(awk -v d="$3" 'BEGIN { print d - 0.01 }')" vol "$2"; }
partial 0.5 0.30 9
partial 1 0.25 7
partial 1.19 0.18 5
partial 1.5 0.10 4
partial 2 0.16 4
partial 2.66 0.06 2.5
partial 3.01 0.05 2
sox -m -v 1 "$tmp/p0.5.wav" -v 1 "$tmp/p1.wav" -v 1 "$tmp/p1.19.wav" -v 1 "$tmp/p1.5.wav" \
    -v 1 "$tmp/p2.wav" -v 1 "$tmp/p2.66.wav" -v 1 "$tmp/p3.01.wav" "$tmp/bell.wav"
sox -m -v 1 "|sox $tmp/bell.wav -p pad 4" -v 0.9 "|sox $tmp/bell.wav -p pad 7.6" \
    -v 0.8 "|sox $tmp/bell.wav -p pad 11.2" "$tmp/tolls.wav" vol 0.4 \
    lowpass 1800 highpass 120 reverb 70 50 100 pad 0 50
sox "$tmp/tolls.wav" "$tmp/minute.wav" trim 0 64
finish bed-bells.ogg -6 "$tmp/minute.wav"
