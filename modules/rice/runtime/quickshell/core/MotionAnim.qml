import QtQuick

// ── MotionAnim ────────────────────────────────────────────────
// The one animation primitive. Attach inside a Behavior on any
// numeric property (opacity = fade, scale = scale, x/y = slide)
// and point it at a Motion spec:
//
//   Behavior on opacity { MotionAnim { spec: Motion.panelOpen } }
//
// The spec may be a binding (e.g. open ? panelOpen : panelClose).

NumberAnimation {
    property var spec: Motion.stateChange

    duration: spec && spec.duration !== undefined ? spec.duration : 0
    easing.type: spec && spec.easing !== undefined ? spec.easing : Easing.Linear
}
