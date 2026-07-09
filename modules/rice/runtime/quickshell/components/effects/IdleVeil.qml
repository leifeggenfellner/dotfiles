import QtQuick
import "../../core"

// ── IdleVeil ─────────────────────────────────────────────────
// Transient idle-warning wash for Phase 21. It is a visual hint,
// not lock ownership: hypridle/hyprlock still perform the real
// session actions, while this effect dissolves as soon as the
// ambient governor clears ShellState.idleApproaching.

Item {
    id: root

    property bool active: false
    property color tint: "black"
    property color fogTint: "white"
    property real strength: 0.28
    property real progress: active ? 1 : 0
    property real _shaderTime: 0

    visible: progress > 0.01
    opacity: progress

    ShaderSurface {
        id: shaderVeil
        anchors.fill: parent
        shaderName: "idle-veil"
        tint: root.tint
        strength: root.strength
        progress: root.progress
        time: root._shaderTime
        speed: 0.45
        edgeSoftness: 0.16
    }

    Timer {
        interval: 66
        repeat: true
        running: shaderVeil.usingShader && root.active && root.visible
        onTriggered: root._shaderTime += interval / 1000
    }

    Rectangle {
        anchors.fill: parent
        visible: !shaderVeil.usingShader
        color: root.tint
        opacity: root.strength * 0.48
    }

    FogLayer {
        anchors.fill: parent
        visible: !shaderVeil.usingShader
        tint: root.fogTint
        strength: root.strength * 0.36
        speed: 0.45
        band: "full"
        running: root.active
    }

    VignetteLayer {
        anchors.fill: parent
        visible: !shaderVeil.usingShader
        tint: root.tint
        strength: root.strength * 1.35
    }

    Behavior on progress {
        MotionAnim {
            spec: root.active ? Motion.panelOpen : Motion.panelClose
        }
    }
}
