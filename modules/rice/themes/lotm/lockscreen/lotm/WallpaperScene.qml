import QtQuick

// ── WallpaperScene ────────────────────────────────────────────
// The lock's backdrop (D-091): the desktop wallpaper, alive but
// quiet. A slow drift (zoom and pan, 80 s each way) and a few dust
// motes rising through the light. Nothing reacts to input beyond
// wake(); on `leaving` the picture eases in a touch as the lock
// fades out.
//
// Motion pauses after `idleAfter` ms without `wake()`, holding its
// place; `reduceMotion` keeps the picture still and the motes away.
// If `source` fails to load, `fallback` is tried once.

Item {
    id: scene

    property url source
    property url fallback
    property bool reduceMotion: false
    property int idleAfter: 30000
    property bool leaving: false

    readonly property bool ready: picture.status === Image.Ready
    property bool awake: true
    readonly property bool moving: awake && !reduceMotion

    function wake() {
        awake = true;
        idle.restart();
    }

    clip: true

    Timer {
        id: idle
        interval: scene.idleAfter
        running: true
        onTriggered: scene.awake = false
    }

    Image {
        id: picture
        anchors.fill: parent
        source: scene.source
        fillMode: Image.PreserveAspectCrop
        // A 4K wallpaper decoded at screen size plus the drift margin.
        sourceSize: Qt.size(Math.ceil(scene.width * 1.12), Math.ceil(scene.height * 1.12))
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: scene.ready ? 1 : 0

        onStatusChanged: {
            if (status === Image.Error && scene.fallback.toString().length > 0 && source !== scene.fallback)
                source = scene.fallback;
        }

        // 0 → 1 → 0 across the drift; the picture never shows an edge.
        property real drift: 0

        scale: 1.05 + 0.04 * drift + (scene.leaving ? 0.025 : 0)
        transform: Translate {
            x: (picture.drift - 0.5) * scene.width * 0.018
            y: (0.5 - picture.drift) * scene.height * 0.01
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            enabled: scene.leaving
            NumberAnimation {
                duration: 450
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation on drift {
            loops: Animation.Infinite
            running: !scene.reduceMotion
            paused: running && !scene.awake
            NumberAnimation {
                from: 0
                to: 1
                duration: 80000
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                from: 1
                to: 0
                duration: 80000
                easing.type: Easing.InOutSine
            }
        }
    }

    // Dust in the light: small, soft, slow. Each mote rises the
    // height of the screen over 20–36 s, swaying, fading in and out.
    Repeater {
        model: scene.reduceMotion ? 0 : 22

        Rectangle {
            id: mote

            required property int index
            // Stable pseudo-random per mote, so a reload looks the same.
            readonly property real r1: (Math.sin(index * 12.9898) * 43758.5453) % 1
            readonly property real r2: (Math.sin(index * 78.233) * 12543.1234) % 1
            readonly property real r3: (Math.sin(index * 37.719) * 24634.6345) % 1
            readonly property real u1: Math.abs(r1)
            readonly property real u2: Math.abs(r2)
            readonly property real u3: Math.abs(r3)

            property real t: u3
            readonly property real f: t % 1

            width: (1.5 + 2.5 * u2) * scene.height / 1080
            height: width
            radius: width / 2
            color: "#fff1d6"
            x: scene.width * (0.06 + 0.88 * u1) + Math.sin((t + u2) * Math.PI * 2 * (1 + u3)) * scene.width * 0.012
            y: scene.height * (1.04 - 1.12 * f)
            opacity: (0.12 + 0.28 * u2) * Math.sin(Math.PI * f)

            NumberAnimation on t {
                from: mote.u3
                to: mote.u3 + 1
                duration: 20000 + 16000 * mote.u1
                loops: Animation.Infinite
                running: true
                paused: !scene.awake
            }
        }
    }
}
