pragma Singleton
import QtQuick

QtObject {
    id: solver

    // ── Inputs (set by bar each layout pass) ─────────────────
    property real viewportWidth: 0
    property real viewportHeight: 0
    property real leftOccupied: 0   // right edge of left-lane content
    property real rightOccupied: 0  // left edge of right-lane content
    property real laneGap: 12       // minimum gap between lanes and center
    property real maxCenterShift: 18

    // ── Resolved outputs ─────────────────────────────────────
    // Center clock
    property real clockResolvedX: 0
    property bool clockShifted: false

    // Overlay resolved positions (keyed by overlay id)
    property var resolvedPositions: ({})

    // ── Solve center-lane clock ──────────────────────────────
    // clockWidth: intrinsic width of clock element
    // Returns resolved X position (left edge) within the safe lane.
    function solveCenter(clockWidth) {
        let safeLeft = leftOccupied + laneGap;
        let safeRight = viewportWidth - rightOccupied - laneGap;
        let safeWidth = safeRight - safeLeft;
        let idealX = (viewportWidth - clockWidth) / 2;

        if (safeWidth >= clockWidth) {
            // Keep visual center first; only apply a bounded nudge on tight monitors.
            let resolved = idealX;
            if (resolved < safeLeft)
                resolved = Math.min(idealX + maxCenterShift, safeLeft);
            if (resolved > safeRight - clockWidth)
                resolved = Math.max(idealX - maxCenterShift, safeRight - clockWidth);

            clockShifted = (Math.abs(resolved - idealX) > 1);
            clockResolvedX = resolved;
        } else {
            // Extremely tight — keep true center to avoid pronounced off-center feeling.
            clockResolvedX = idealX;
            clockShifted = true;
        }
        return clockResolvedX;
    }

    // ── Solve transient overlay placement ────────────────────
    // Resolves desired position with edge-clamp and collision avoidance.
    // entry: { id, desiredX, desiredY, width, height, type }
    // occupied: array of { x, y, width, height, type } rects to avoid
    function solveOverlay(entry, occupied) {
        let x = entry.desiredX;
        let y = entry.desiredY;
        let w = entry.width;
        let h = entry.height;

        // Edge clamp horizontal
        x = Math.max(laneGap, Math.min(x, viewportWidth - w - laneGap));

        // Edge clamp vertical (keep within viewport)
        if (y + h > viewportHeight)
            y = viewportHeight - h - 4;
        if (y < 0)
            y = 4;

        // Collision displacement: shift horizontally if overlapping higher-priority overlay
        for (let i = 0; i < occupied.length; i++) {
            let occ = occupied[i];
            if (_intersects(x, y, w, h, occ.x, occ.y, occ.width, occ.height)) {
                // If occupied rect is to the left of center, push right; otherwise push left
                if (occ.x + occ.width / 2 < viewportWidth / 2) {
                    x = occ.x + occ.width + laneGap;
                } else {
                    x = occ.x - w - laneGap;
                }
                // Re-clamp after shift
                x = Math.max(laneGap, Math.min(x, viewportWidth - w - laneGap));
            }
        }

        let result = { x: x, y: y };
        let positions = resolvedPositions;
        positions[entry.id] = result;
        resolvedPositions = positions;
        return result;
    }

    // ── Suppression check ────────────────────────────────────
    // Returns true if this overlay should be hidden due to higher-priority collision.
    function shouldSuppress(entry, occupied) {
        for (let i = 0; i < occupied.length; i++) {
            let occ = occupied[i];
            if (occ.type > entry.type) {
                // Higher priority occupies same zone — suppress lower
                if (_intersects(entry.desiredX, entry.desiredY, entry.width, entry.height,
                                occ.x, occ.y, occ.width, occ.height))
                    return true;
            }
        }
        return false;
    }

    // ── Geometry helpers ─────────────────────────────────────
    function _intersects(x1, y1, w1, h1, x2, y2, w2, h2) {
        return !(x1 + w1 <= x2 || x2 + w2 <= x1 || y1 + h1 <= y2 || y2 + h2 <= y1);
    }
}
