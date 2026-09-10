import QtQuick
import "../core"

Item {
    id: root

    required property int workspaceId
    required property bool active
    required property color workspaceColor
    required property string iconSpec

    signal activated(int workspaceId)

    readonly property bool iconIsImage: Theme.iconIsFile(iconSpec)

    width: Theme.metrics.workspaces.slotSize
    height: Theme.metrics.workspaces.slotSize

    Rectangle {
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

    Image {
        visible: root.iconIsImage
        anchors.centerIn: parent
        width: Theme.metrics.workspaces.iconSize
        height: Theme.metrics.workspaces.iconSize
        source: root.iconIsImage ? Theme.assetUrl(root.iconSpec) : ""
        sourceSize.width: Theme.metrics.workspaces.iconSourceSize
        sourceSize.height: Theme.metrics.workspaces.iconSourceSize
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.active ? 1 : 0.45

        Behavior on opacity {
            MotionAnim {}
        }
    }

    Text {
        visible: !root.iconIsImage
        anchors.centerIn: parent
        text: root.iconIsImage ? "" : root.iconSpec
        color: root.workspaceColor
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.icon
        opacity: root.active ? 1 : 0.45

        Behavior on opacity {
            MotionAnim {}
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.activated(root.workspaceId)
    }
}
