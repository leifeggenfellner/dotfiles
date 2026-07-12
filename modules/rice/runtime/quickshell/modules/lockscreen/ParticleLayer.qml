import QtQuick
import "./utils/VeilMath.js" as VeilMath

Item {
    id: root

    property real time: 0
    property int count: 96
    property real opacityScale: 0.5
    property color accent: "white"
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true
    property bool burstMode: false

    function emitAt(x, y) {
        burstRepeater.model += 1;
        const item = burstRepeater.itemAt(burstRepeater.model - 1);
        if (item)
            item.fire(x, y);
        if (burstRepeater.model > 18)
            burstRepeater.model = 0;
    }

    Repeater {
        model: root.burstMode ? 0 : root.count

        Item {
            id: particle

            required property int index
            readonly property real a: VeilMath.hash(index * 11.13 + 0.7)
            readonly property real b: VeilMath.hash(index * 19.91 + 4.2)
            readonly property real c: VeilMath.hash(index * 29.71 + 8.4)
            readonly property int kind: index % 13 === 0 ? 3 : index % 5
            readonly property real drift: root.time * (0.010 + a * 0.018)
            readonly property real twinkle: 0.45 + 0.55 * Math.sin(root.time * (0.9 + c) + a * 9.0)

            x: root.width * VeilMath.fract(a + drift * (0.45 + b)) + root.parallaxX * (0.15 + c * 0.35)
            y: root.height * VeilMath.fract(b - drift * (0.60 + a)) + root.parallaxY * (0.10 + a * 0.32)
            opacity: root.opacityScale * (0.12 + twinkle * 0.46) * (kind === 1 ? 0.55 : 1.0)
            rotation: (root.time * (8 + a * 18) + b * 360) % 360

            Rectangle {
                visible: particle.kind !== 3
                anchors.centerIn: parent
                width: particle.kind === 2 ? 3 : 2
                height: width
                radius: width / 2
                color: particle.kind === 1 ? "#9a9a9a" : root.accent
                opacity: particle.kind === 1 ? 0.45 : 1
            }

            Text {
                visible: particle.kind === 3
                anchors.centerIn: parent
                text: ["+", "*", ".", "x"][particle.index % 4]
                color: root.accent
                opacity: 0.42
                font.pixelSize: 9 + Math.round(particle.c * 5)
            }
        }
    }

    Repeater {
        id: burstRepeater
        model: 0

        Item {
            id: burst

            required property int index
            property real originX: 0
            property real originY: 0
            property real life: 0

            function fire(x, y) {
                originX = x;
                originY = y;
                life = 0;
                burstAnim.restart();
            }

            x: originX
            y: originY
            opacity: 1 - life

            Repeater {
                model: 7

                Rectangle {
                    required property int index
                    readonly property real angle: index / 7 * Math.PI * 2
                    width: 3
                    height: 3
                    radius: 1.5
                    color: root.accent
                    x: Math.cos(angle) * burst.life * 34
                    y: Math.sin(angle) * burst.life * 22
                    opacity: 1 - burst.life
                }
            }

            NumberAnimation {
                id: burstAnim
                target: burst
                property: "life"
                from: 0
                to: 1
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
    }
}
