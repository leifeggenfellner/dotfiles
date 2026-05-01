import QtQuick
import "../.."
import "../../services" as Services
import "./" as Bar
import "./popouts" as Popouts

Bar.SigilPopupBase {
    id: popup

    namespaceTag: "lotm-connection-popup"
    openState: Services.NetworkState.panelOpen
    keyboardFocusOnDemand: true
    accentColor: _pathwayColor()
    popupWidth: 520
    popupHeight: 600

    property string overlayId: ""

    function _pathwayColor() {
        const activeWs = String(Services.HyprState.activeWorkspace);
        const data = Services.ThemeLoader.pathways;
        for (let i = 0; i < data.length; i++) {
            if (String(data[i].workspace) === activeWs)
                return Qt.color(data[i].color);
        }
        return Theme.accent;
    }

    onCloseRequested: Services.NetworkState.panelOpen = false

    onAboutToOpen: {
        overlayId = Services.OverlayManager.push({
            type: Services.OverlayManager.typeCommand,
            role: "network",
            anchor: "top-right",
            desiredX: popup.x,
            desiredY: popup.y,
            width: popup.popupWidth,
            height: popup.popupHeight
        });
    }

    onAboutToClose: {
        if (overlayId !== "")
            Services.OverlayManager.remove(overlayId);
        overlayId = "";
    }

    Popouts.ConnectionPopupContent {
        anchors.fill: parent
        pathwayColor: popup.accentColor
        onRequestClose: Services.NetworkState.panelOpen = false
    }
}
