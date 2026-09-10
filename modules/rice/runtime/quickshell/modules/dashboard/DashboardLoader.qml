import QtQuick
import "../../core"
import "../../widgets"

Loader {
    id: loader

    required property var modelData

    readonly property bool requested: ShellState.dashboardOpen
    readonly property bool retainWhenClosed: Registry.byRegion("dashboard").some(descriptor => !descriptor.unloadWhenClosed)

    active: retainWhenClosed || requested || (item !== null && item.visible)
    sourceComponent: Dashboard {
        modelData: loader.modelData
    }
}
