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
    case "$out" in
        *.ogg) sox "$tmp/joined.wav" -C 3 "$out" gain "$gain" ;;
        *) sox "$tmp/joined.wav" -b 16 "$out" gain "$gain" ;;
    esac
}

# Sound beds (D-058) loop forever, so they are rendered as small Ogg files
# and made seamless here.

# impulses <out.wav> <seconds> <per second> <seed>: a sparse train of
# random-height clicks (rain drops, record crackle) once filtered. The
# seed keeps every render the same.
impulses() {
    awk -v d="$2" -v n="$3" -v seed="$4" 'BEGIN {
    srand(seed); r = 8000
    print "; Sample Rate " r; print "; Channels 1"
    for (i = 0; i < d * r; i++) printf "%.6f %.4f\n", i / r, (rand() < n / r ? rand() * 1.2 - 0.6 : 0)
  }' > "$tmp/impulses.dat"
    sox "$tmp/impulses.dat" -r 44100 -b 16 "$1"
}

# loop <in.wav> <out.wav> <seconds> <crossfade>: the first <seconds> of
# <in>, with the <crossfade> seconds after them faded over the start, so
# the end runs into the beginning without a seam. <in> must be at least
# <seconds> + <crossfade> long.
loop() {
    local in="$1" out="$2" len="$3" x="$4"
    sox "$in" "$tmp/loop-head.wav" trim 0 "$x" fade q "$x"
    sox "$in" "$tmp/loop-tail.wav" trim "$len" "$x" fade q 0 "$x" "$x"
    sox -m -v 1 "$tmp/loop-head.wav" -v 1 "$tmp/loop-tail.wav" "$tmp/loop-seam.wav"
    sox "$in" "$tmp/loop-body.wav" trim "$x" "$(awk -v l="$len" -v x="$x" 'BEGIN { print l - x }')"
    sox "$tmp/loop-seam.wav" "$tmp/loop-body.wav" "$out"
}
