import QtQuick

Item {
    id: root

    property real time: 0
    property color tint: "white"
    property real strength: 0.25
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true

    clip: true

    Repeater {
        model: 5

        Canvas {
            id: blob

            required property int index
            readonly property real seed: (index * 0.618034 + 0.19) % 1

            width: Math.max(1, root.width * (0.62 + seed * 0.48))
            height: Math.max(1, root.height * (0.30 + seed * 0.22))
            y: root.height * (0.48 + seed * 0.32) + root.parallaxY * (0.2 + seed * 0.24)
            opacity: root.strength * (0.42 + seed * 0.36)
            x: -width + root.width * ((root.time * (0.010 + seed * 0.008) + seed * 1.7) % 2.25) + root.parallaxX * (0.35 + seed * 0.18)

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const cx = width * (0.45 + seed * 0.1);
                const cy = height * 0.58;
                const radius = width * 0.55;
                const gradient = ctx.createRadialGradient(cx, cy, 0, cx, cy, radius);
                gradient.addColorStop(0.0, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.55));
                gradient.addColorStop(0.45, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.18));
                gradient.addColorStop(1.0, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0));
                ctx.fillStyle = gradient;
                ctx.fillRect(0, 0, width, height);
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: root
                function onTintChanged() {
                    blob.requestPaint();
                }
            }
        }
    }
}
