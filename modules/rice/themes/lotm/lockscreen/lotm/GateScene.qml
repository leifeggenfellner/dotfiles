import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// ── GateScene ─────────────────────────────────────────────────
// Chanis Gate (D-084): the lock's backdrop, a painted gate in a crypt
// (gate/base.png), brought to life over the still image:
//   • candle light flickers on both sconces;
//   • a faint moonlight band crosses the gate once a minute;
//   • `lit` (0–7) of the seven medallions glow, one per typed
//     character, outer pairs first and the moon last;
//   • deny(): the medallions go dark, the lock plate flares red and
//     the leaves rattle;
//   • open(): the leaves swing inward on their hinges onto pale light,
//     then everything fades to black (openDuration ms).
// After dark (20:00–06:00) the crypt is colder and the candles lower.
// Motion pauses after `idleAfter` ms without `wake()`.
//
// Positions are in the image's own pixels at 1456×816 (the reference
// it was measured on), so they hold at any size. Wide screens crop
// the image to cover; tall ones fit it whole over a blurred copy.

Item {
    id: scene

    property url source: Qt.resolvedUrl("gate/base.png")
    property int lit: 0
    property int idleAfter: 30000
    readonly property int openDuration: 1300
    readonly property bool ready: base.status === Image.Ready
    readonly property bool night: {
        const h = clock.hour;
        return h >= 20 || h < 6;
    }

    // Where the UI may sit: the lock plate, in scene pixels.
    readonly property point plateCenter: at(737, 578)
    readonly property real plateBottom: at(737, 622).y

    property bool active: true
    property bool opening: false

    function wake() {
        scene.active = true;
        idle.restart();
    }

    function deny() {
        scene.wake();
        denyAnim.restart();
    }

    function open() {
        scene.opening = true;
        openAnim.restart();
    }

    // ── Geometry ─────────────────────────────────────────────
    readonly property real refW: 1456
    readonly property real refH: 816
    readonly property bool fitWhole: width / Math.max(1, height) < 1.3
    readonly property real k: fitWhole ? width / refW : Math.max(width / refW, height / refH)
    readonly property real pw: refW * k
    readonly property real ph: refH * k
    readonly property real ox: (width - pw) / 2
    readonly property real oy: (height - ph) / 2

    // Reference pixels → scene pixels.
    function at(x, y) {
        return Qt.point(ox + x * k, oy + y * k);
    }

    // The gate's leaves: the riveted arch from hinge to hinge, split at
    // the centre seam.
    readonly property real gateLeft: 372
    readonly property real gateRight: 1102
    readonly property real seam: 737
    readonly property real gateTop: 232
    readonly property real gateFoot: 740

    // Seven medallions, in lighting order: wheat, swords, trident,
    // cogwheel, sun, eye, moon.
    readonly property var emblems: [
        { x: 465, y: 350, r: 46 },
        { x: 1007, y: 350, r: 46 },
        { x: 530, y: 263, r: 45 },
        { x: 945, y: 263, r: 45 },
        { x: 620, y: 201, r: 45 },
        { x: 855, y: 202, r: 45 },
        { x: 737, y: 172, r: 57 }
    ]
    readonly property var candles: [
        { x: 300, y: 552 },
        { x: 1172, y: 546 }
    ]

    QtObject {
        id: clock
        property int hour: new Date().getHours()
    }
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: clock.hour = new Date().getHours()
    }

    Timer {
        id: idle
        interval: scene.idleAfter
        running: true
        onTriggered: scene.active = false
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    // Tall screens: the scene blurred and dimmed behind the whole image.
    Image {
        visible: scene.fitWhole
        anchors.fill: parent
        source: scene.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        layer.enabled: visible
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: 64
            brightness: -0.55
        }
    }

    // ── The still ────────────────────────────────────────────
    Item {
        id: stage
        x: scene.ox
        y: scene.oy
        width: scene.pw
        height: scene.ph

        Image {
            id: base
            anchors.fill: parent
            source: scene.source
            asynchronous: true
            smooth: true
            mipmap: true
        }

        // Night: colder and darker (the leaves carry their own).
        NightTint {
            anchors.fill: parent
        }

        // Beyond the gate: dark until it opens onto pale light.
        Item {
            anchors.fill: parent
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: gateMask
            }

            Rectangle {
                anchors.fill: parent
                color: "#020403"
            }
            Glow {
                cx: scene.seam
                cy: 540
                radius: 460
                color: "#efe6cf"
                opacity: beyond.light
            }
            Glow {
                cx: scene.seam
                cy: 600
                radius: 200
                color: "#fff8e8"
                opacity: beyond.light * 0.8
            }
            QtObject {
                id: beyond
                property real light: 0
            }
        }

        // The two leaves, cut from the still, hinged at their outer edges.
        Leaf {
            id: leftLeaf
            mask: leftMask
            hinge: scene.gateLeft * scene.k
            swing: 1
        }
        Leaf {
            id: rightLeaf
            mask: rightMask
            hinge: scene.gateRight * scene.k
            swing: -1
        }

        // Moonlight crossing the gate.
        Item {
            anchors.fill: parent
            clip: true
            Rectangle {
                id: moonband
                width: parent.width * 0.14
                height: parent.height * 2
                y: -parent.height * 0.5
                x: -width * 2
                rotation: 18
                opacity: scene.night ? 0.1 : 0.06
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }
                    GradientStop {
                        position: 0.5
                        color: "#bfe0e6"
                    }
                    GradientStop {
                        position: 1
                        color: "transparent"
                    }
                }
            }
            SequentialAnimation {
                running: scene.active && !scene.opening
                loops: Animation.Infinite
                NumberAnimation {
                    target: moonband
                    property: "x"
                    from: -moonband.width * 2
                    to: stage.width + moonband.width
                    duration: 9000
                    easing.type: Easing.InOutSine
                }
                PauseAnimation {
                    duration: 51000
                }
            }
        }

        // Candle light.
        Repeater {
            model: scene.candles
            delegate: Glow {
                id: candle
                required property var modelData
                property real flicker: 1
                cx: modelData.x
                cy: modelData.y
                radius: 58
                color: "#ffb35c"
                opacity: (scene.night ? 0.5 : 0.85) * flicker
                Behavior on flicker {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.InOutSine
                    }
                }
                Timer {
                    interval: 90 + Math.random() * 70
                    repeat: true
                    running: scene.active && !scene.opening
                    onTriggered: candle.flicker = 0.72 + Math.random() * 0.34
                }
            }
        }

        // The medallions: lit one per character, faintly alive at night.
        Repeater {
            id: emblemRepeater
            model: scene.emblems
            delegate: Item {
                id: emblem
                required property var modelData
                required property int index
                readonly property bool on: index < scene.lit
                property real drain: 1

                Glow {
                    cx: emblem.modelData.x
                    cy: emblem.modelData.y
                    radius: emblem.modelData.r * 1.9
                    color: "#ffcf6e"
                    // A halo round the disc, thin over its face, so the
                    // emblem still reads through the light.
                    halo: true
                    opacity: (emblem.on ? 0.9 : (scene.night ? 0.12 : 0)) * emblem.drain
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }
                Rectangle {
                    readonly property point c: Qt.point(emblem.modelData.x * scene.k, emblem.modelData.y * scene.k)
                    x: c.x - width / 2
                    y: c.y - height / 2
                    width: emblem.modelData.r * 2.04 * scene.k
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: Math.max(1.5, 2.2 * scene.k)
                    border.color: "#ffd98a"
                    opacity: (emblem.on ? 0.7 : 0) * emblem.drain
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 280
                        }
                    }
                }
            }
        }

        // The lock plate's flare when the passphrase is refused.
        Glow {
            id: flare
            cx: scene.seam
            cy: 578
            radius: 120
            color: "#ff3b2a"
            opacity: 0
        }

        // Shapes for the masks (drawn only into layers).
        Shape {
            id: gateMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            ShapePath {
                fillColor: "white"
                strokeWidth: -1
                PathSvg {
                    path: scene.archPath(scene.gateLeft, scene.gateRight)
                }
            }
        }
        Shape {
            id: leftMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            ShapePath {
                fillColor: "white"
                strokeWidth: -1
                PathSvg {
                    path: scene.archPath(scene.gateLeft, scene.seam)
                }
            }
        }
        Shape {
            id: rightMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            ShapePath {
                fillColor: "white"
                strokeWidth: -1
                PathSvg {
                    path: scene.archPath(scene.seam, scene.gateRight)
                }
            }
        }
    }

    // The final fade to black as the gate stands open.
    Rectangle {
        id: blackout
        anchors.fill: parent
        color: "black"
        opacity: 0
    }

    // The arch between two x positions (reference pixels → stage
    // pixels): straight jambs, then curves meeting at the apex over the
    // seam. A half arch keeps its side of the curve.
    function archPath(x0, x1) {
        const s = scene.k;
        const L = scene.gateLeft, R = scene.gateRight, top = scene.gateTop, foot = scene.gateFoot, spring = 560;
        const p = (x, y) => (x * s).toFixed(1) + " " + (y * s).toFixed(1);
        const leftHalf = "M " + p(L, foot) + " L " + p(L, spring) + " C " + p(L, 380) + " " + p(560, 240) + " " + p(scene.seam, top);
        const rightHalf = " C " + p(914, 240) + " " + p(R, 380) + " " + p(R, spring) + " L " + p(R, foot);
        if (x0 === L && x1 === R)
            return leftHalf + rightHalf + " Z";
        if (x1 === scene.seam)
            return leftHalf + " L " + p(scene.seam, foot) + " Z";
        return "M " + p(scene.seam, foot) + " L " + p(scene.seam, top) + rightHalf + " Z";
    }

    // ── Pieces ───────────────────────────────────────────────
    component NightTint: Rectangle {
        color: "#04121c"
        opacity: scene.night ? 0.42 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 2000
            }
        }
    }


    // A radial glow at a reference point.
    component Glow: Shape {
        id: glow
        property real cx: 0
        property real cy: 0
        property real radius: 50
        property color color: "white"
        property bool halo: false
        readonly property real r: radius * scene.k

        x: cx * scene.k - r
        y: cy * scene.k - r
        width: r * 2
        height: r * 2
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: glow.r
                centerY: glow.r
                centerRadius: glow.r
                focalX: glow.r
                focalY: glow.r
                GradientStop {
                    position: 0
                    color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, glow.halo ? 0.16 : 1)
                }
                GradientStop {
                    position: glow.halo ? 0.42 : 0.35
                    color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, glow.halo ? 0.22 : 0.45)
                }
                GradientStop {
                    position: glow.halo ? 0.56 : 0.6
                    color: Qt.rgba(glow.color.r, glow.color.g, glow.color.b, glow.halo ? 0.55 : 0.15)
                }
                GradientStop {
                    position: 1
                    color: "transparent"
                }
            }
            PathAngleArc {
                centerX: glow.r
                centerY: glow.r
                radiusX: glow.r
                radiusY: glow.r
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // A gate leaf: the still, masked to one half of the arch, turning
    // about its hinge. `swing` 1 opens the left leaf inward, -1 the right.
    component Leaf: Item {
        id: leaf
        property Item mask
        property real hinge: 0
        property int swing: 1
        property real angle: 0
        property real shake: 0

        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: leaf.mask
        }

        Image {
            anchors.fill: parent
            source: scene.source
            asynchronous: true
            smooth: true
            mipmap: true
        }
        NightTint {
            anchors.fill: parent
        }
        // The leaf darkens as it turns away from the candles.
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: Math.abs(leaf.angle) / 90 * 0.6
        }

        transform: [
            Translate {
                x: leaf.shake
            },
            Rotation {
                origin.x: leaf.hinge
                origin.y: scene.ph / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: leaf.angle * leaf.swing
            }
        ]
    }

    // ── Moments ──────────────────────────────────────────────
    SequentialAnimation {
        id: denyAnim
        ParallelAnimation {
            ScriptAction {
                script: {
                    for (let i = 0; i < emblemRepeater.count; i++)
                        emblemRepeater.itemAt(i).drain = 0;
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: flare
                    property: "opacity"
                    to: 0.9
                    duration: 90
                }
                NumberAnimation {
                    target: flare
                    property: "opacity"
                    to: 0
                    duration: 700
                    easing.type: Easing.InQuad
                }
            }
            SequentialAnimation {
                loops: 3
                ParallelAnimation {
                    NumberAnimation {
                        target: leftLeaf
                        property: "shake"
                        to: 2.5 * scene.k
                        duration: 45
                    }
                    NumberAnimation {
                        target: rightLeaf
                        property: "shake"
                        to: -2.5 * scene.k
                        duration: 45
                    }
                }
                ParallelAnimation {
                    NumberAnimation {
                        target: leftLeaf
                        property: "shake"
                        to: -1.5 * scene.k
                        duration: 45
                    }
                    NumberAnimation {
                        target: rightLeaf
                        property: "shake"
                        to: 1.5 * scene.k
                        duration: 45
                    }
                }
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: leftLeaf
                property: "shake"
                to: 0
                duration: 60
            }
            NumberAnimation {
                target: rightLeaf
                property: "shake"
                to: 0
                duration: 60
            }
        }
        ScriptAction {
            script: {
                for (let i = 0; i < emblemRepeater.count; i++)
                    emblemRepeater.itemAt(i).drain = 1;
            }
        }
    }

    SequentialAnimation {
        id: openAnim
        ParallelAnimation {
            NumberAnimation {
                target: leftLeaf
                property: "angle"
                to: 78
                duration: 950
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: rightLeaf
                property: "angle"
                to: 78
                duration: 950
                easing.type: Easing.InOutCubic
            }
            NumberAnimation {
                target: beyond
                property: "light"
                to: 1
                duration: 700
                easing.type: Easing.OutQuad
            }
        }
        NumberAnimation {
            target: blackout
            property: "opacity"
            to: 1
            duration: 330
            easing.type: Easing.InQuad
        }
    }
}
