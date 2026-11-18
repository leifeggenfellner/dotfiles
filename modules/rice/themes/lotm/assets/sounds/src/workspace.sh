#!/usr/bin/env bash
# shellcheck disable=SC2154 source=/dev/null  # $tmp comes from lib.sh
# workspace: a soft whisper, kept well under the other cues because it
# fires often.
. "$(dirname "$0")/lib.sh"
gen "$tmp/breath.wav" synth 0.24 pinknoise sinc 900-3600 tremolo 6 30 fade h 0.08 0.24 0.14 vol 0.4
finish workspace.wav -12 "$tmp/breath.wav"
