import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../core"
import "../../components/effects"

// ── AwakeningOverlay ─────────────────────────────────────────
// The session fog-lift (D-053), one per screen: the screen opens
// veiled, the theme's words surface through the fog beside the real
// user and time, then veil and fog rise away together. Its input
// region is empty and it takes no keyboard focus, so the session is
// usable from the first frame; the controller unloads it when done.

PanelWindow {
    id: overlay

    required property var modelData
    screen: modelData

    // The fallback only covers the frame between clearing and unload.
    readonly property var awakening: ShellState.awakening ?? ({ title: "", subtitle: "", hold: 0, lift: 300, backdrop: "" })
    readonly property int hold: awakening.hold
    readonly property int lift: awakening.lift

    visible: ShellState.awakening !== null

    WlrLayershell.namespace: "rice-awakening"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    mask: Region {}

    // The veil: the theme's backdrop (the boot splash's last frame,
    // D-085) or plain sunken colour, lifted away with the fog.
    Rectangle {
        id: veil
        anchors.fill: parent
        color: Theme.colors.bg.sunken

        Image {
            anchors.fill: parent
            visible: (overlay.awakening.backdrop ?? "").length > 0
            source: visible ? overlay.awakening.backdrop : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            smooth: true
        }
    }

    // Taller than the screen so its lower edge stays offscreen as it rises.
    FogLayer {
        id: fog
        width: parent.width
        height: parent.height * 1.4
        tint: Theme.colors.accent.secondary
        strength: 0.55
        speed: 1.6
        band: "full"
    }

    Column {
        id: words
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.42
        spacing: Theme.metrics.space.sm
        opacity: 0

        // Over a backdrop the words need a shadow to read.
        layer.enabled: (overlay.awakening.backdrop ?? "").length > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "black"
            shadowBlur: 0.8
            shadowOpacity: 0.85
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 1
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: overlay.awakening.title
            color: Theme.colors.accent.primary
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.heading * 2
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text.length > 0
            text: overlay.awakening.subtitle
            color: Theme.colors.fg.muted
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.heading
            font.italic: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Quickshell.env("USER") + "  ·  " + Qt.formatDateTime(new Date(), "dddd d MMMM  ·  HH:mm")
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }

    SequentialAnimation {
        running: true

        NumberAnimation {
            target: words
            property: "opacity"
            to: 1
            duration: Motion.awaken.duration
            easing.type: Motion.awaken.easing
        }
        PauseAnimation {
            duration: overlay.hold
        }
        ParallelAnimation {
            NumberAnimation {
                target: veil
                property: "opacity"
                to: 0
                duration: overlay.lift
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: fog
                property: "opacity"
                to: 0
                duration: overlay.lift
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                target: fog
                property: "y"
                to: -overlay.height * 0.35
                duration: overlay.lift
                easing.type: Easing.InOutSine
            }
            NumberAnimation {
                target: words
                property: "opacity"
                to: 0
                duration: overlay.lift * 0.45
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: words
                property: "y"
                to: overlay.height * 0.36
                duration: overlay.lift
                easing.type: Easing.InOutSine
            }
        }
    }
}
