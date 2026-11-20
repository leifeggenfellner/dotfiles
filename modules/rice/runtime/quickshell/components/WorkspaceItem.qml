import QtQuick
import QtQuick.Effects
import "../core"

// ── WorkspaceItem ─────────────────────────────────────────────
// One workspace slot. Without `bezel` it is the plain ring-and-icon
// slot. With `bezel` (D-065) the icon sits in a theme plate and shows
// four states: empty (monochrome, faint), occupied (inked, with a
// rivet below), active (the polished plate, full colour and a glow in
// the workspace colour) and urgent (the rim pulses twice in
// `urgentColor`, then holds).
// Left click activates; middle click asks to move the focused window.

Item {
    id: root

    required property int workspaceId
    required property bool active
    required property color workspaceColor
    required property string iconSpec
    property bool occupied: false
    property bool urgent: false
    // { plate?; activePlate?; } from widgets.workspaces.settings.bezel
    property var bezel: null
    property color urgentColor: Theme.colors.state.danger

    signal activated(int workspaceId)
    signal moveRequested(int workspaceId)

    readonly property bool iconIsImage: Theme.iconIsFile(iconSpec)
    readonly property bool bezeled: bezel !== null
    readonly property real iconOpacity: {
        if (active)
            return 1;
        if (!bezeled)
            return 0.45;
        return occupied ? 0.8 : 0.45;
    }

    width: Theme.metrics.workspaces.slotSize
    height: Theme.metrics.workspaces.slotSize

    // ── Bezel plates ──────────────────────────────────────────
    Image {
        visible: root.bezeled && (root.bezel.plate ?? "").length > 0
        anchors.fill: parent
        source: visible ? Theme.assetUrl(root.bezel.plate) : ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        smooth: true
    }

    Image {
        visible: root.bezeled && (root.bezel.activePlate ?? "").length > 0
        anchors.fill: parent
        source: visible ? Theme.assetUrl(root.bezel.activePlate) : ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        smooth: true
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            MotionAnim {}
        }
    }

    Rectangle {
        visible: !root.bezeled
        anchors.centerIn: parent
        width: parent.width + Theme.metrics.workspaces.ringExpansion
        height: parent.height + Theme.metrics.workspaces.ringExpansion
        radius: width / 2
        color: "transparent"
        border.width: 1
        border.color: root.workspaceColor
        opacity: root.active ? 0.9 : 0

        Behavior on opacity {
            MotionAnim {}
        }
    }

    // Urgent rim (bezel only): pulses twice when the notice arrives,
    // then holds until the workspace is visited.
    Rectangle {
        id: urgentRim
        visible: root.bezeled && root.urgent
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.urgentColor

        SequentialAnimation on opacity {
            id: urgentPulse
            running: false
            loops: 2

            MotionAnim {
                to: 0.25
                spec: Motion.alarm
            }
            MotionAnim {
                to: 1
                spec: Motion.alarm
            }
        }
    }

    onUrgentChanged: {
        urgentRim.opacity = 1;
        if (bezeled && urgent && Motion.enabled)
            urgentPulse.restart();
    }

    Image {
        id: sigil
        visible: root.iconIsImage
        anchors.centerIn: parent
        width: Theme.metrics.workspaces.iconSize
        height: Theme.metrics.workspaces.iconSize
        source: root.iconIsImage ? Theme.assetUrl(root.iconSpec) : ""
        sourceSize.width: Theme.metrics.workspaces.iconSourceSize
        sourceSize.height: Theme.metrics.workspaces.iconSourceSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.iconOpacity

        layer.enabled: root.bezeled
        layer.effect: MultiEffect {
            saturation: root.occupied || root.active ? 0 : -1
            shadowEnabled: root.active
            shadowColor: root.workspaceColor
            shadowBlur: 0.7
            shadowOpacity: 0.9
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }

        Behavior on opacity {
            MotionAnim {}
        }
    }

    Text {
        visible: !root.iconIsImage
        anchors.centerIn: parent
        text: root.iconIsImage ? "" : root.iconSpec
        color: root.bezeled && !root.occupied && !root.active ? Theme.colors.fg.subtle : root.workspaceColor
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.icon
        opacity: root.iconOpacity

        Behavior on opacity {
            MotionAnim {}
        }
    }

    // Occupied: one brass rivet under the bezel.
    Rectangle {
        visible: root.bezeled && root.occupied && !root.active
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 1
        width: 4
        height: 4
        radius: 2
        color: Theme.colors.accent.frame
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                root.moveRequested(root.workspaceId);
            else
                root.activated(root.workspaceId);
        }
    }
}
