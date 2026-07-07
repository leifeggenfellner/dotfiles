import QtQuick

// ── ParticleField ─────────────────────────────────────────────
// T1 ambient primitive: a sparse set of motes rising slowly.
// Count is capped upstream by core/Effects (structural budget);
// per-mote variety is deterministic (golden-ratio spread), so the
// field looks organic without Math.random re-rolls on reload.
//
// Presentation-only; `running` is owned by the mounting surface.

Item {
    id: field

    property color tint: "transparent"
    property real strength: 0.3   // peak mote opacity
    property real speed: 1.0
    property int count: 8
    property bool running: true

    clip: true

    Repeater {
        model: field.count

        Rectangle {
            id: mote

            required property int index

            // Deterministic per-mote variety in [0,1).
            readonly property real u: (index * 0.618034 + 0.213) % 1
            readonly property int riseMs: Math.round((16000 + u * 12000) / field.speed)

            width: 2 + Math.round(u * 2)
            height: width
            radius: width / 2
            color: field.tint
            opacity: 0
            x: field.width * ((u * 7.13) % 1)
            y: field.height + height

            SequentialAnimation {
                running: field.running && field.visible
                loops: Animation.Infinite

                // Stagger so motes don't rise as one synchronized wave.
                PauseAnimation {
                    duration: Math.round(mote.u * 9000)
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: mote
                        property: "y"
                        from: field.height + mote.height
                        to: field.height * 0.2
                        duration: mote.riseMs
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: mote
                            property: "opacity"
                            from: 0
                            to: field.strength
                            duration: Math.round(mote.riseMs * 0.25)
                        }
                        PauseAnimation {
                            duration: Math.round(mote.riseMs * 0.4)
                        }
                        NumberAnimation {
                            target: mote
                            property: "opacity"
                            to: 0
                            duration: Math.round(mote.riseMs * 0.35)
                        }
                    }
                }
            }
        }
    }
}
