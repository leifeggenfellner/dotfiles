pragma Singleton
import QtQuick

// ── Fuzzy ─────────────────────────────────────────────────────
// Pure fuzzy ranking helper. It owns no state and has no side
// effects, so services and UI code can share one matcher without
// inventing per-surface scoring rules.

QtObject {
    id: fuzzy

    function normalize(value) {
        return String(value ?? "").toLowerCase().replace(/[^a-z0-9]+/g, " ").trim();
    }

    function scoreText(text, query) {
        const haystack = normalize(text);
        const needle = normalize(query);
        if (needle.length === 0)
            return 1;
        if (haystack.length === 0)
            return -1;
        if (haystack === needle)
            return 10000 - haystack.length;
        if (haystack.startsWith(needle))
            return 9000 - haystack.length;

        const words = haystack.split(" ");
        for (let i = 0; i < words.length; i++) {
            if (words[i].startsWith(needle))
                return 8000 - i * 25 - words[i].length;
        }

        let pos = -1;
        let first = -1;
        let gaps = 0;
        for (let i = 0; i < needle.length; i++) {
            const next = haystack.indexOf(needle[i], pos + 1);
            if (next < 0)
                return -1;
            if (first < 0)
                first = next;
            if (pos >= 0)
                gaps += next - pos - 1;
            pos = next;
        }
        return 6000 - first * 40 - gaps * 12 - haystack.length;
    }

    function bestScore(fields, query) {
        let best = -1;
        for (let i = 0; i < fields.length; i++) {
            const value = fields[i];
            if (Array.isArray(value)) {
                for (let j = 0; j < value.length; j++)
                    best = Math.max(best, scoreText(value[j], query));
            } else {
                best = Math.max(best, scoreText(value, query));
            }
        }
        return best;
    }
}
