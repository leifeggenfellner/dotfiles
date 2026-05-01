pragma Singleton
import QtQuick

// ── Motion ────────────────────────────────────────────────────
// The single source of animation parameters (D-010). UI code
// references semantic specs — never inline durations or curves.
// Specs resolve from Theme motion tokens and collapse to 0ms when
// motion is disabled, so every animation is correct without motion.
//
// v1 vocabulary (grown only when a surface needs a new name):
//   panelOpen   — a surface/panel entering
//   panelClose  — a surface/panel leaving (faster, sharper)
//   stateChange — small state reactions (hover, value changes)

QtObject {
    id: motion

    readonly property bool enabled: Theme.motion.enabled

    readonly property QtObject panelOpen: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.base : 0
        readonly property int easing: Theme.motion.easings.enter
    }

    readonly property QtObject panelClose: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.exit
    }

    readonly property QtObject stateChange: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.standard
    }
}
