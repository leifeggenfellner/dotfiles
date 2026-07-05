import QtQuick
import "../../core"
import "../../components"

// ── PowerGlance ───────────────────────────────────────────────
// Power icon; all actions live in the popout. No services.

Item {
    id: root

    property var services: ({})
    property var settings: ({})

    implicitWidth: icon.width
    implicitHeight: Theme.metrics.bar.height

    Icon {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        name: "power"
        color: Theme.colors.fg.muted
    }
}
