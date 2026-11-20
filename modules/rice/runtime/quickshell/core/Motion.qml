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
//   cardFlip    — small card reveal/selection turn
//   ritualAssemble — infrequent radial/delegate assembly motion
//   instrumentSettle — a brass part turning to a new reading (D-063)
//   alarm       — one beat of a critical warning pulse (D-064)
//   revolution  — one linear turn of a playing disc (D-064)
//   stateChange — small state reactions (hover, value changes)
//   awaken      — one-shot startup reveal of surface contents
//   fade        — a cross-fade that survives reduce-motion (D-070)
//   hingeSwing / hingeSettle — a plate swinging down from its hinge,
//                 then settling flat from a small overshoot (D-070)
//
// enabled folds in the global reduce-motion pref (D-022): the pref
// lives in PrefsState and is pushed onto ShellState by the modules
// layer, because core may not import services.
//
// Reduce-motion (D-070): moments that turn or sweep (the cog, the
// needle, the carousel drum, the hinged plates) become a cross-fade
// rather than a jump. `fade` keeps its duration under reduce-motion and
// is 0 only when the theme turns motion off; calm(spec) is `spec` while
// motion is on and `fade` otherwise, for the opacity half of a moment.

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

    readonly property QtObject cardFlip: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.base : 0
        readonly property int easing: Theme.motion.easings.emphasis
    }

    readonly property QtObject ritualAssemble: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.ceremonial : 0
        readonly property int easing: Theme.motion.easings.enter
    }

    readonly property QtObject instrumentSettle: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.ceremonial : 0
        readonly property int easing: Theme.motion.easings.emphasis
    }

    readonly property QtObject alarm: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.slow : 0
        readonly property int easing: Theme.motion.easings.standard
    }

    readonly property QtObject revolution: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.ceremonial * 4 : 0
        readonly property int easing: Easing.Linear
    }

    readonly property QtObject stateChange: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.standard
    }

    readonly property QtObject fade: QtObject {
        readonly property int duration: Theme.motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.standard
    }

    readonly property QtObject hingeSwing: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.base : 0
        readonly property int easing: Theme.motion.easings.enter
    }

    readonly property QtObject hingeSettle: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.fast : 0
        readonly property int easing: Theme.motion.easings.standard
    }

    function calm(spec) {
        return motion.enabled ? spec : motion.fade;
    }

    readonly property QtObject awaken: QtObject {
        readonly property int duration: motion.enabled ? Theme.motion.durations.slow : 0
        readonly property int easing: Theme.motion.easings.enter
    }
}
