import QtQuick

// ── VignetteLayer ─────────────────────────────────────────────
// Static edge-darkening wash: a radial gradient painted once
// (repainted only on resize/tint change). Costs nothing at steady
// state — it is a texture, not an animation — but lives with the
// ambient primitives so one governor gates all atmosphere.

Item {
    id: vignette

    property color tint: "transparent"
    property real strength: 0.2

    Canvas {
        id: wash

        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const cx = width / 2;
            const cy = height / 2;
            const r = Math.sqrt(cx * cx + cy * cy);
            const g = ctx.createRadialGradient(cx, cy, r * 0.55, cx, cy, r);
            g.addColorStop(0, Qt.rgba(vignette.tint.r, vignette.tint.g, vignette.tint.b, 0));
            g.addColorStop(1, Qt.rgba(vignette.tint.r, vignette.tint.g, vignette.tint.b, vignette.strength));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: vignette
            function onTintChanged() {
                wash.requestPaint();
            }
            function onStrengthChanged() {
                wash.requestPaint();
            }
        }
    }
}
