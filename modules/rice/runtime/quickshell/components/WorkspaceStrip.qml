pragma ComponentBehavior: Bound
import QtQuick
import "../core"

// ── WorkspaceStrip ────────────────────────────────────────────
// A row of WorkspaceItems. With `bezel` (D-065) items show their
// window and urgent state, and a needle under the row sweeps to the
// active one on Motion.instrumentSettle. `windows` and `urgent` are
// { id: count } / { id: true } maps from the caller.

Item {
    id: root

    required property var items
    required property int activeWorkspace
    property var windows: ({})
    property var urgent: ({})
    // { plate?; activePlate?; needle?; urgent? } or null
    property var bezel: null
    property color urgentColor: Theme.colors.state.danger

    signal workspaceActivated(int workspaceId)
    signal moveRequested(int workspaceId)

    readonly property int activeIndex: items.findIndex(i => i.id === activeWorkspace)
    readonly property string needle: bezel ? (bezel.needle ?? "") : ""

    implicitWidth: row.width
    implicitHeight: row.height

    Row {
        id: row

        spacing: Theme.metrics.space.sm

        Repeater {
            id: repeater

            model: root.items

            delegate: Item {
                id: delegateItem

                required property var modelData

                width: workspaceItem.width
                height: workspaceItem.height

                WorkspaceItem {
                    id: workspaceItem

                    workspaceId: delegateItem.modelData.id
                    active: delegateItem.modelData.id === root.activeWorkspace
                    workspaceColor: delegateItem.modelData.color ?? Theme.colors.accent.primary
                    iconSpec: delegateItem.modelData.icon ?? ""
                    occupied: (root.windows[delegateItem.modelData.id] ?? 0) > 0
                    urgent: root.urgent[delegateItem.modelData.id] ?? false
                    bezel: root.bezel
                    urgentColor: root.urgentColor
                    onActivated: workspaceId => root.workspaceActivated(workspaceId)
                    onMoveRequested: workspaceId => root.moveRequested(workspaceId)
                }
            }
        }
    }

    // The needle points up at the active bezel from below the row.
    Image {
        readonly property Item target: root.activeIndex >= 0 && root.activeIndex < repeater.count ? repeater.itemAt(root.activeIndex) : null

        visible: root.needle.length > 0 && target !== null
        width: Theme.metrics.workspaces.slotSize * 0.4
        height: width
        x: target ? target.x + (target.width - width) / 2 : 0
        anchors.top: row.bottom
        anchors.topMargin: 1
        source: root.needle.length > 0 ? Theme.assetUrl(root.needle) : ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        smooth: true

        Behavior on x {
            MotionAnim {
                spec: Motion.instrumentSettle
            }
        }
    }
}
