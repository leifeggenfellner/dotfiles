import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components/effects"

// ── MoodBackdrop ─────────────────────────────────────────────
// Per-monitor backdrop for a workspace mood (D-045): the mood's image
// over the wallpaper, under the ambient layers and every window, with
// the theme's caption beside the real workspace name. An optional
// veil fogs the backdrop itself: a flat wash and a rolling fog sea. The
// image shows on battery too; the fog only drifts while ambient runs
// and holds still otherwise. Input-transparent and loaded only while
// this screen's mood has a backdrop. The last mood is kept while it fades
// out, so leaving does not pop.

PanelWindow {
    id: backdrop

    required property var modelData
    screen: modelData

    readonly property var mood: ShellState.moods[modelData.name]
    readonly property bool shown: !!(mood && mood.backdrop)
    property var _last: ({})

    // Test the mood itself: `shown` may not have re-evaluated yet
    // when this handler runs.
    function _remember() {
        if (mood && mood.backdrop)
            _last = mood;
    }
    onMoodChanged: _remember()
    Component.onCompleted: _remember()

    visible: shown || content.opacity > 0.01

    // Background, mapped after the wallpaper client's surface, so it
    // draws above the wallpaper and below the ambient Bottom layer.
    WlrLayershell.namespace: "rice-mood"
    WlrLayershell.layer: WlrLayer.Background
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

    Item {
        id: content

        anchors.fill: parent
        opacity: backdrop.shown ? 1 : 0

        Behavior on opacity {
            MotionAnim {
                spec: backdrop.shown ? Motion.ritualAssemble : Motion.surfaceConceal
            }
        }

        Image {
            anchors.fill: parent
            source: Theme.assetUrl(backdrop._last.backdrop ?? "")
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: backdrop.width
            asynchronous: true
            cache: false
        }

        Rectangle {
            anchors.fill: parent
            visible: !!backdrop._last.veil
            color: backdrop._last.veil?.tint ?? "transparent"
            opacity: backdrop._last.veil?.wash ?? 0
        }

        // A thin haze over everything, then the dense sea along the floor.
        FogLayer {
            anchors.fill: parent
            visible: !!backdrop._last.veil
            tint: backdrop._last.veil?.tint ?? "transparent"
            strength: (backdrop._last.veil?.density ?? 0) * 0.55
            speed: 0.35
            band: "full"
            running: ShellState.ambientActive
        }
        FogLayer {
            anchors.fill: parent
            visible: !!backdrop._last.veil
            tint: backdrop._last.veil?.tint ?? "transparent"
            strength: backdrop._last.veil?.density ?? 0
            speed: 0.55
            band: "bottom"
            running: ShellState.ambientActive
        }

        Column {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: Theme.metrics.space.lg * 2
            spacing: Theme.metrics.space.xs

            Text {
                visible: text.length > 0
                text: backdrop._last.title ?? ""
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.heading
            }
            Text {
                text: "workspace " + (backdrop._last.workspace ?? "")
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
