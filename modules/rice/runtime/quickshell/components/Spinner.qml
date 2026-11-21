import QtQuick
import "../core"

// ── Spinner ───────────────────────────────────────────────────
// Pending work: an arc that turns. Under reduce-motion it breathes
// in place instead of turning.

Item {
    id: root

    property int size: Theme.typography.sizes.body
    property color color: Theme.colors.accent.primary
    property bool running: visible

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: arc
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.lineWidth = Math.max(1.5, root.size / 8);
            ctx.lineCap = "round";
            ctx.strokeStyle = root.color;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - ctx.lineWidth, 0, Math.PI * 1.4);
            ctx.stroke();
        }
        Connections {
            target: root
            function onColorChanged() {
                arc.requestPaint();
            }
        }

        RotationAnimator on rotation {
            running: root.running && Motion.enabled
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
        }
        SequentialAnimation on opacity {
            running: root.running && !Motion.enabled
            loops: Animation.Infinite
            NumberAnimation {
                to: 0.35
                duration: 700
            }
            NumberAnimation {
                to: 1
                duration: 700
            }
        }
    }
}
