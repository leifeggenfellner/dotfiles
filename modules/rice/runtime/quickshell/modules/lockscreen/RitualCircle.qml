import QtQuick

Item {
    id: root

    property real time: 0
    property color tint: "white"
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true

    x: parallaxX
    y: parallaxY
    rotation: time * 1.4
    scale: 1 + Math.sin(time * 0.28) * 0.012

    Canvas {
        id: sigil

        anchors.fill: parent
        opacity: 0.62

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width;
            const h = height;
            const cx = w / 2;
            const cy = h / 2;
            const r = Math.min(w, h) * 0.45;
            ctx.strokeStyle = Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.34);
            ctx.lineWidth = 1;
            for (let ring = 0; ring < 4; ring += 1) {
                ctx.beginPath();
                ctx.arc(cx, cy, r * (0.52 + ring * 0.14), 0, Math.PI * 2);
                ctx.stroke();
            }
            for (let i = 0; i < 24; i += 1) {
                const a = i / 24 * Math.PI * 2;
                const inner = r * 0.68;
                const outer = r * (i % 3 === 0 ? 0.93 : 0.84);
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
                ctx.lineTo(cx + Math.cos(a) * outer, cy + Math.sin(a) * outer);
                ctx.stroke();
            }
            ctx.globalAlpha = 0.24;
            ctx.beginPath();
            for (let p = 0; p < 7; p += 1) {
                const a = p / 7 * Math.PI * 2 - Math.PI / 2;
                const x = cx + Math.cos(a) * r * 0.57;
                const y = cy + Math.sin(a) * r * 0.57;
                if (p === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            ctx.stroke();
        }
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onTintChanged() {
                sigil.requestPaint();
            }
        }
    }

    Repeater {
        model: 12

        Text {
            required property int index
            readonly property real angle: index / 12 * Math.PI * 2

            x: root.width / 2 + Math.cos(angle) * root.width * 0.37 - width / 2
            y: root.height / 2 + Math.sin(angle) * root.height * 0.37 - height / 2
            text: ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"][index]
            color: root.tint
            opacity: 0.28
            font.pixelSize: Math.max(9, root.width * 0.018)
            rotation: -root.rotation
        }
    }
}
