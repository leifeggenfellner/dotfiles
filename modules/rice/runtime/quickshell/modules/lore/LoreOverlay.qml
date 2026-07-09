import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components/effects"

// ── LoreOverlay ──────────────────────────────────────────────
// Input-transparent flavor-event surface. It renders only in
// response to ShellState event edges, so with all world-event
// settings disabled it stays unmapped and costs nothing.

PanelWindow {
    id: overlay

    required property var modelData
    screen: modelData

    property int _seenFlavorSerial: 0
    property int _seenSurgeSerial: 0
    property bool messageActive: false
    property bool surgeActive: false
    property string messageText: ""
    property string messageKind: ""

    visible: messageActive || messageCard.opacity > 0.01 || surgeActive || surgeFog.opacity > 0.01

    WlrLayershell.namespace: "rice-lore"
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

    Connections {
        target: ShellState

        function onFlavorEventSerialChanged() {
            if (ShellState.flavorEventSerial <= overlay._seenFlavorSerial || ShellState.flavorEventText.length === 0)
                return;
            overlay._seenFlavorSerial = ShellState.flavorEventSerial;
            overlay.messageText = ShellState.flavorEventText;
            overlay.messageKind = ShellState.flavorEventKind;
            overlay.messageActive = true;
            messageTimer.restart();
        }

        function onFogSurgeSerialChanged() {
            if (ShellState.fogSurgeSerial <= overlay._seenSurgeSerial)
                return;
            overlay._seenSurgeSerial = ShellState.fogSurgeSerial;
            overlay.surgeActive = true;
            surgeTimer.restart();
        }
    }

    Timer {
        id: messageTimer
        interval: 4200
        onTriggered: overlay.messageActive = false
    }

    Timer {
        id: surgeTimer
        interval: 6200
        onTriggered: overlay.surgeActive = false
    }

    FogLayer {
        id: surgeFog
        anchors.fill: parent
        visible: overlay.surgeActive || opacity > 0.01
        opacity: overlay.surgeActive ? 1 : 0
        tint: Theme.colors.accent.secondary
        strength: 0.18
        speed: 1.8
        band: "full"
        running: overlay.surgeActive

        Behavior on opacity {
            MotionAnim {
                spec: overlay.surgeActive ? Motion.panelOpen : Motion.panelClose
            }
        }
    }

    Rectangle {
        id: messageCard
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.metrics.bar.height + Theme.metrics.bar.margin * 2
        width: Math.min(620, Math.max(360, message.implicitWidth + Theme.metrics.space.lg * 2))
        height: message.implicitHeight + Theme.metrics.space.md * 2
        radius: Theme.metrics.radius.medium
        color: Theme.colors.bg.mantle
        border.width: 1
        border.color: Theme.colors.accent.secondary
        opacity: overlay.messageActive ? 0.96 : 0

        Behavior on opacity {
            MotionAnim {
                spec: overlay.messageActive ? Motion.panelOpen : Motion.panelClose
            }
        }

        Text {
            id: message
            anchors.fill: parent
            anchors.margins: Theme.metrics.space.md
            text: overlay.messageText
            color: Theme.colors.fg.primary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.body
        }
    }
}
