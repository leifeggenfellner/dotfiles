import QtQuick
import "../core"

// ── FadeIn ────────────────────────────────────────────────────
// The reduce-motion stand-in for a turn or sweep (D-070): call
// play() when the reading changes and `target` fades back in on
// Motion.fade. Does nothing while motion is on, since the turn itself
// plays then. The target's opacity must not be bound.
//
//   FadeIn { id: settleFade; target: needle }
//   onActiveIndexChanged: settleFade.play()

SequentialAnimation {
    id: fadeIn

    required property Item target

    function play() {
        if (!Motion.enabled && Motion.fade.duration > 0)
            fadeIn.restart();
    }

    PropertyAction {
        target: fadeIn.target
        property: "opacity"
        value: 0
    }
    MotionAnim {
        target: fadeIn.target
        property: "opacity"
        to: 1
        spec: Motion.fade
    }
}
