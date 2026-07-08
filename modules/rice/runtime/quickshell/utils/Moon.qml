pragma Singleton
import QtQuick

// ── Moon ─────────────────────────────────────────────────────
// Pure lunar phase helper for dashboard divination surfaces. The
// calculation is approximate, local-only, and good enough for UI
// labeling without introducing a network dependency.

QtObject {
    id: moon

    readonly property real cycleDays: 29.530588853
    readonly property double knownNewMoon: Date.UTC(2000, 0, 6, 18, 14, 0)

    function phase(date) {
        const d = date ?? new Date();
        const days = (d.getTime() - knownNewMoon) / 86400000;
        const age = ((days % cycleDays) + cycleDays) % cycleDays;
        const fraction = age / cycleDays;
        const illumination = (1 - Math.cos(2 * Math.PI * fraction)) / 2;
        return {
            age: age,
            fraction: fraction,
            illumination: illumination,
            name: _name(fraction),
            icon: _icon(fraction)
        };
    }

    function _name(fraction) {
        if (fraction < 0.03 || fraction >= 0.97)
            return "new moon";
        if (fraction < 0.22)
            return "waxing crescent";
        if (fraction < 0.28)
            return "first quarter";
        if (fraction < 0.47)
            return "waxing gibbous";
        if (fraction < 0.53)
            return "full moon";
        if (fraction < 0.72)
            return "waning gibbous";
        if (fraction < 0.78)
            return "last quarter";
        return "waning crescent";
    }

    function _icon(fraction) {
        if (fraction < 0.03 || fraction >= 0.97)
            return "moon-new";
        if (fraction < 0.22)
            return "moon-waxing-crescent";
        if (fraction < 0.28)
            return "moon-first-quarter";
        if (fraction < 0.47)
            return "moon-waxing-gibbous";
        if (fraction < 0.53)
            return "moon-full";
        if (fraction < 0.72)
            return "moon-waning-gibbous";
        if (fraction < 0.78)
            return "moon-last-quarter";
        return "moon-waning-crescent";
    }
}
