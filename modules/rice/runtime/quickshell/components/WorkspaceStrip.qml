pragma ComponentBehavior: Bound
import QtQuick
import "../core"

Row {
    id: root

    required property var items
    required property int activeWorkspace

    signal workspaceActivated(int workspaceId)

    spacing: Theme.metrics.space.sm

    Repeater {
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
                onActivated: workspaceId => root.workspaceActivated(workspaceId)
            }
        }
    }
}
