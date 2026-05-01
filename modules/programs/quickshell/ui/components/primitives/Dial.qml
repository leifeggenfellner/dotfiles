import QtQuick
import "../../"

// ── Dial ─────────────────────────────────────────────────────
// Two concentric arc rings. Used as clock base.
//   outerProgress: 0..1 -> outer ring angle (24-hour)
//   innerProgress: 0..1 -> inner ring angle (minute)

Canvas {
    id: dial

    property real outerProgress: 0.0
    property real innerProgress: 0.0
    property color ringColor: Theme.accent
    property color trackColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08)
    property real outerRadius: width / 2 - 4
    property real innerRadius: width / 2 - 12
    property real lineWidth: 2.5

    implicitWidth: 96
    implicitHeight: 96

    onOuterProgressChanged: requestPaint()
    onInnerProgressChanged: requestPaint()
    onRingColorChanged: requestPaint()

    onPaint: {
        let ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        let cx = width / 2;
        let cy = height / 2;
        let startAngle = -Math.PI / 2;
        let tau = 2 * Math.PI;

        // Outer track
        ctx.beginPath();
        ctx.arc(cx, cy, outerRadius, 0, tau);
        ctx.strokeStyle = trackColor;
        ctx.lineWidth = lineWidth;
        ctx.stroke();

        // Outer progress (24-hour)
        ctx.beginPath();
        ctx.arc(cx, cy, outerRadius, startAngle, startAngle + outerProgress * tau);
        ctx.strokeStyle = ringColor;
        ctx.lineWidth = lineWidth;
        ctx.stroke();

        // Inner track
        ctx.beginPath();
        ctx.arc(cx, cy, innerRadius, 0, tau);
        ctx.strokeStyle = trackColor;
        ctx.lineWidth = lineWidth;
        ctx.stroke();

        // Inner progress (60-minute)
        ctx.beginPath();
        ctx.arc(cx, cy, innerRadius, startAngle, startAngle + innerProgress * tau);
        ctx.strokeStyle = Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 0.6);
        ctx.lineWidth = lineWidth;
        ctx.stroke();
    }
}
