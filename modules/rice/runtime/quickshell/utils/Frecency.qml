pragma Singleton
import QtQuick

// ── Frecency ──────────────────────────────────────────────────
// Pure launch-history math. A history is a plain object
// { <id>: { count, last } } with `last` in epoch milliseconds; callers
// own where it is stored. Recency weights decay in age buckets (the
// Firefox scheme), so a few recent launches outrank many stale ones.

QtObject {
    id: frecency

    // Entries beyond this many ids are dropped, lowest score first.
    readonly property int capacity: 64

    function weight(ageMs) {
        const hour = 3600 * 1000;
        if (ageMs < 4 * hour)
            return 1;
        if (ageMs < 24 * hour)
            return 0.8;
        if (ageMs < 7 * 24 * hour)
            return 0.5;
        if (ageMs < 30 * 24 * hour)
            return 0.3;
        return 0.1;
    }

    function score(entry, nowMs) {
        if (!entry || !(entry.count > 0))
            return 0;
        return entry.count * weight(Math.max(0, nowMs - (entry.last ?? 0)));
    }

    // Map of id → score for every id in `history`.
    function scores(history, nowMs) {
        const result = {};
        for (const id in history ?? {})
            result[id] = score(history[id], nowMs);
        return result;
    }

    // A new history with one more launch of `id`; the input is untouched.
    function record(history, id, nowMs) {
        const next = JSON.parse(JSON.stringify(history ?? {}));
        const entry = next[id] ?? { count: 0, last: 0 };
        next[id] = { count: entry.count + 1, last: nowMs };

        const ids = Object.keys(next);
        if (ids.length > capacity) {
            ids.sort((a, b) => score(next[a], nowMs) - score(next[b], nowMs));
            for (let i = 0; i < ids.length - capacity; i++)
                delete next[ids[i]];
        }
        return next;
    }
}
