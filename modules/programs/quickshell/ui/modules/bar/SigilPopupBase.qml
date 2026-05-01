import QtQuick
import Quickshell
import Quickshell.Wayland
import "../.."

PanelWindow {
    id: base

    required property var modelData
    required property string namespaceTag
    required property bool openState

    property color accentColor: Theme.accent
    property bool keyboardFocusOnDemand: false
    property int hoverCloseDelayMs: 300
    property int popupWidth: 520
    property int popupHeight: 600
    property int extraTopMargin: 0
    property int rightMargin: Theme.barMargin
    property bool enableEscape: true
    property color frameColor: Qt.rgba(Theme.mantle.r, Theme.mantle.g, Theme.mantle.b, 0.94)
    property real frameBorderOpacity: 0.35
    property int frameRadius: 14
    property bool useScaleAnimation: true

    default property alias contentChildren: contentArea.data

    signal closeRequested
    signal aboutToOpen
    signal aboutToClose

    screen: modelData
    WlrLayershell.namespace: namespaceTag
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keyboardFocusOnDemand && openState ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: -1
    color: "transparent"
    implicitWidth: popupWidth
    implicitHeight: popupHeight

    anchors {
        top: true
        right: true
    }
    margins {
        top: Theme.barHeight + Theme.barMargin * 2 + base.extraTopMargin
        right: base.rightMargin
    }

    visible: openState || fadeTimer.running

    Timer {
        id: fadeTimer
        interval: Theme.animDurationOverlay
    }

    onOpenStateChanged: {
        if (openState)
            base.aboutToOpen();
        else {
            fadeTimer.restart();
            base.aboutToClose();
        }
    }

    Item {
        id: stage
        anchors.fill: parent
        opacity: base.openState ? 1.0 : 0.0
        focus: base.openState && base.keyboardFocusOnDemand

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDurationOverlay
                easing.type: Easing.OutCubic
            }
        }

        Keys.onEscapePressed: {
            if (base.enableEscape)
                base.closeRequested();
        }

        Rectangle {
            id: frame
            anchors.fill: parent
            radius: base.frameRadius
            color: base.frameColor
            border.width: 1
            border.color: Qt.rgba(base.accentColor.r, base.accentColor.g, base.accentColor.b, base.frameBorderOpacity)

            scale: base.useScaleAnimation ? (base.openState ? 1.0 : 0.96) : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animDurationOverlay
                    easing.type: Easing.OutCubic
                }
            }

            transform: Translate {
                y: base.useScaleAnimation ? (base.openState ? 0 : -8) : 0
                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animDurationOverlay
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        HoverHandler {
            id: hoverHandler
            onHoveredChanged: {
                if (hovered)
                    closeDelay.stop();
                else if (base.openState && base.hoverCloseDelayMs > 0)
                    closeDelay.restart();
                else if (!hovered && base.openState && base.hoverCloseDelayMs === 0)
                    base.closeRequested();
            }
        }

        Timer {
            id: closeDelay
            interval: base.hoverCloseDelayMs
            repeat: false
            onTriggered: base.closeRequested()
        }

        Item {
            id: contentArea
            anchors.fill: parent
        }
    }
}
