# shellcheck shell=bash
# Shared by the cue recipes (D-057); source it, don't run it.
# Each recipe builds parts in $tmp with sox, then calls `finish` to
# join them and level the result to the set's loudness.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[1]}")/.."
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# 44.1 kHz mono 16-bit, like sealed-letter.wav and red-seal.wav.
gen() { sox -n -r 44100 -c 1 -b 16 "$@"; }

# finish <out.wav> <offset dB> <part.wav>...: concatenates the parts and
# sets the RMS level to the set's target (about that of sealed-letter.wav)
# plus the offset, keeping peaks under -3 dBFS.
finish() {
    local out="$1" offset="$2"
    shift 2
    sox "$@" "$tmp/joined.wav"
    local rms peak gain
    rms="$(sox "$tmp/joined.wav" -n stat 2>&1 | awk '/RMS +amplitude/ {print $3}')"
    peak="$(sox "$tmp/joined.wav" -n stat 2>&1 | awk '/Maximum amplitude/ {print $3}')"
    gain="$(awk -v r="$rms" -v p="$peak" -v o="$offset" 'BEGIN {
    g = 20 * log(0.085 / r) / log(10) + o
    cap = 20 * log(0.708 / p) / log(10)
    printf "%.2f", (g < cap ? g : cap)
  }')"
    sox "$tmp/joined.wav" -b 16 "$out" gain "$gain"
}
