import QtQuick
import "../../"
import "../../services" as Services
import "../../modules/bar" as BarModules

// ── PopoutShell ───────────────────────────────────────────────
// Unified popout container. Binds open state to PopoutController.
// Usage: set popoutId to a unique string; put content in the
//        default property (contentChildren).

Item {
    id: shell

    required property string popoutId
    required property var modelData

    property int popoutWidth: 520
    property int popoutHeight: 600
    property int extraTopMargin: 0
    property bool keyboardFocus: false

    default property alias contentChildren: base.contentChildren

    readonly property bool isOpen: Services.PopoutController.activePopout === popoutId

    function open() {
        Services.PopoutController.requestOpen(popoutId);
    }
    function close() {
        Services.PopoutController.requestClose();
    }
    function toggle() {
        Services.PopoutController.toggle(popoutId);
    }

    BarModules.SigilPopupBase {
        id: base
        modelData: shell.modelData
        namespaceTag: "arcanum-popout-" + shell.popoutId
        openState: shell.isOpen
        popupWidth: shell.popoutWidth
        popupHeight: shell.popoutHeight
        extraTopMargin: shell.extraTopMargin
        keyboardFocusOnDemand: shell.keyboardFocus

        onCloseRequested: shell.close()
    }
}
