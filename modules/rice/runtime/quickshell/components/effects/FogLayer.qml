import QtQuick

// ── FogLayer ──────────────────────────────────────────────────
// T1 ambient primitive (contracts/motion-contract.md): soft
// gradient blobs drifting slowly across a band of the surface.
// Each blob is a Canvas painted ONCE to a texture; steady-state
// cost is transform + opacity animation only — no repaints.
//
// Theme-neutral and presentation-only: tint/strength/speed arrive
// resolved from core/Effects via the mounting surface, which also
// owns the `running` gate (ShellState.ambientActive). Blobs start
// fully offscreen and drift in, so a (re)start never pops.

Item {
    id: fog

    property color tint: "transparent"
    property real strength: 0.1   // peak blob opacity
    property real speed: 1.0      // 1.0 = base drift tempo
    property string band: "bottom" // bottom | top | full
    property bool running: true

    clip: true

    readonly property real _bandH: band === "full" ? height : height * 0.45

    Repeater {
        model: 3

        Canvas {
            id: blob

            required property int index

            width: Math.max(1, fog.width * (0.45 + 0.22 * index))
            height: Math.max(1, fog._bandH)
            y: fog.band === "top" ? 0 : fog.height - fog._bandH
            opacity: 0

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const g = ctx.createRadialGradient(
                    width / 2, height * 0.62, 0,
                    width / 2, height * 0.62, width / 2);
                g.addColorStop(0, Qt.rgba(fog.tint.r, fog.tint.g, fog.tint.b, 1));
                g.addColorStop(1, Qt.rgba(fog.tint.r, fog.tint.g, fog.tint.b, 0));
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, height);
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: fog
                function onTintChanged() {
                    blob.requestPaint();
                }
            }

            // Drift: fully offscreen left → fully offscreen right,
            // so the loop's wrap-around is never visible.
            NumberAnimation on x {
                running: fog.running && fog.visible
                loops: Animation.Infinite
                from: -blob.width
                to: fog.width
                duration: (90000 + blob.index * 34000) / fog.speed
            }

            // Breath: slow ±30% opacity oscillation around strength.
            SequentialAnimation on opacity {
                running: fog.running && fog.visible
                loops: Animation.Infinite
                NumberAnimation {
                    to: fog.strength
                    duration: (9000 + blob.index * 2600) / fog.speed
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: fog.strength * 0.7
                    duration: (11000 + blob.index * 2100) / fog.speed
                    easing.type: Easing.InOutSine
                }
            }
        }
    }
}
