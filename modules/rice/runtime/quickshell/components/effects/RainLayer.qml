import QtQuick

// ── RainLayer ────────────────────────────────────────────────
// T1 ambient primitive: fine slanted rain. Two streak textures (near
// and far) are each painted ONCE onto a Canvas twice the surface
// height; steady-state cost is a looping y translation only, no
// repaints. Streak placement is deterministic (golden-ratio spread),
// so a reload looks the same.
//
// Presentation-only; tint/strength/speed/count arrive resolved from
// core/Effects, `running` is owned by the mounting surface.

Item {
    id: rain

    property color tint: "transparent"
    property real strength: 0.18  // peak streak opacity
    property real speed: 1.0
    property int count: 60        // streaks per texture tile
    property bool running: true

    clip: true

    Repeater {
        // 0 = far (thin, faint, slow), 1 = near.
        model: 2

        Item {
            id: sheet

            required property int index

            readonly property real depth: index === 0 ? 0.55 : 1.0
            readonly property int fallMs: Math.round((index === 0 ? 2600 : 1700) / rain.speed)

            width: rain.width
            height: rain.height * 2
            opacity: rain.strength * (index === 0 ? 0.6 : 1.0)

            Canvas {
                id: streaks

                // Tint and density arrive after creation (the mounting
                // Loader sets them), so both trigger the one-time paint.
                readonly property color tint: rain.tint
                readonly property int count: rain.count

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = tint;
                    ctx.lineCap = "round";
                    ctx.lineWidth = sheet.index === 0 ? 1 : 1.5;
                    const tileH = height / 2;
                    const n = Math.round(count * (sheet.index === 0 ? 1.4 : 1));
                    const len = tileH * 0.05 * sheet.depth;
                    for (let i = 0; i < n; i++) {
                        const u = (i * 0.618034 + 0.137 + sheet.index * 0.31) % 1;
                        const v = (i * 0.754877 + 0.29) % 1;
                        const x = u * width;
                        const y = v * tileH;
                        // Same streak in both halves, so the loop is seamless.
                        for (const off of [0, tileH]) {
                            ctx.beginPath();
                            ctx.moveTo(x, y + off);
                            ctx.lineTo(x - len * 0.18, y + off + len);
                            ctx.stroke();
                        }
                    }
                }

                onTintChanged: requestPaint()
                onCountChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            NumberAnimation on y {
                from: -rain.height
                to: 0
                duration: sheet.fallMs
                loops: Animation.Infinite
                running: rain.running && rain.visible
            }
        }
    }
}
