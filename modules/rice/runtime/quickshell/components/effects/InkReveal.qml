import QtQuick
import "../../core"

// ── InkReveal ────────────────────────────────────────────────
// Shader garnish for Motion.surfaceReveal. It never owns the T0
// transition: the surface still fades/scales normally, while this
// overlay adds a brief noise-edged wash when compiled shaders exist.

Item {
    id: root

    property bool open: false
    property color tint: "white"
    property real strength: 0.16
    property real progress: open ? 1 : 0

    visible: open || progress > 0.01
    opacity: open ? 1 : 0

    ShaderSurface {
        anchors.fill: parent
        shaderName: "ink-reveal"
        tint: root.tint
        strength: root.strength
        progress: root.progress
        edgeSoftness: 0.10
    }

    Behavior on progress {
        MotionAnim {
            spec: root.open ? Motion.surfaceReveal : Motion.surfaceConceal
        }
    }
    Behavior on opacity {
        MotionAnim {
            spec: root.open ? Motion.surfaceReveal : Motion.surfaceConceal
        }
    }
}
