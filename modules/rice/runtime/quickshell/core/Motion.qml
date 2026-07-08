pragma Singleton
import QtQuick

// ── Motion ────────────────────────────────────────────────────
// The single source of animation parameters (D-010). UI code
// references semantic specs — never inline durations or curves.
// Specs resolve from Theme motion tokens and collapse to 0ms when
// motion is disabled, so every animation is correct without motion.
//
// v2 vocabulary (grown only when a surface needs a new name):
//   panelOpen   — a surface/panel entering
//   panelClose  — a surface/panel leaving (faster, sharper)
//   surfaceReveal / surfaceConceal — surface-open aliases (D-023)
//   sealPress   — brief confirm/activation pulse
//   ritualAssemble — infrequent radial/delegate assembly motion
//   stateChange — small state reactions (hover, value changes)
//   awaken      — one-shot startup reveal of surface contents
//
// enabled folds in the global reduce-motion pref (D-022): the pref
// lives in PrefsState and is pushed onto ShellState by the modules
// layer, because core may not import services.

QtObject {
    id: motion

    readonly property bool enabled: Theme.motion.enabled && !ShellState.reduceMotion

    readonly property QtObject panelOpen: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.base : 0
        readonly property int easing: Theme.motion.easings.enter
    }

    readonly property QtObject panelClose: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.exit
    }

    // D-023 keeps panelOpen/panelClose as aliases for the migration
    // cycle while new surfaces use the named vocabulary from the plan.
    readonly property QtObject surfaceReveal: panelOpen
    readonly property QtObject surfaceConceal: panelClose

    readonly property QtObject sealPress: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.emphasis
    }

    readonly property QtObject ritualAssemble: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.ceremonial : 0
        readonly property int easing: Theme.motion.easings.enter
    }

    readonly property QtObject stateChange: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.standard
    }

    readonly property QtObject awaken: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.slow : 0
        readonly property int easing: Theme.motion.easings.enter
    }
}
