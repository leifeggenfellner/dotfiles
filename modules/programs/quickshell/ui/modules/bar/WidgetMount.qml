import QtQuick
import QtQuick.Layouts

Item {
    id: mount

    required property var descriptor
    required property var barModelData // screen passed down from Bar

    visible: descriptor && descriptor.enabled
    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Layout.preferredWidth: loader.implicitWidth
    Layout.preferredHeight: loader.implicitHeight

    Loader {
        id: loader
        active: mount.visible
        sourceComponent: mount.descriptor ? mount.descriptor.glanceItem : null
        onLoaded: item.modelData = mount.barModelData
    }
}
