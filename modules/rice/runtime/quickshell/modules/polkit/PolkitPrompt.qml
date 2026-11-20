import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/hypr"
import "../../services/polkit"

// ── PolkitPrompt ──────────────────────────────────────────────
// The session's polkit authentication dialog (D-062). Shows the real
// request (message, identity, action id, PAM prompt) under theme copy
// from Theme.widgetConfig("polkit").settings, on the focused screen only.
//
// The response field is cleared on submit, on close and when a new
// request starts; its text goes only to PolkitState.submit().

PanelWindow {
    id: prompt

    required property var modelData
    screen: modelData

    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === prompt.screen.name
    readonly property bool open: PolkitState.active && onFocusedScreen
    readonly property var settings: Theme.widgetConfig("polkit").settings ?? ({})
    readonly property string title: settings.title ?? "Authentication required"
    readonly property string epigraph: settings.epigraph ?? ""
    readonly property string submitLabel: settings.submitLabel ?? "Authenticate"
    readonly property string cancelLabel: settings.cancelLabel ?? "Cancel"
    readonly property string identityLabel: settings.identityLabel ?? "as"
    readonly property string maskCharacter: settings.maskCharacter ?? "•"
    // PAM usually says nothing on a wrong password; this fills the gap.
    readonly property string retryText: settings.retryText ?? "That didn't work. Try again."
    readonly property string errorText: PolkitState.error.length > 0 ? PolkitState.error : (PolkitState.attemptFailed ? retryText : "")

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || card.opacity > 0.01

    WlrLayershell.namespace: "rice-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    function submit() {
        if (!PolkitState.responseRequired)
            return;
        const value = response.text;
        response.text = "";
        PolkitState.submit(value);
    }

    function cancel() {
        response.text = "";
        PolkitState.cancel();
    }

    onOpenChanged: {
        response.text = "";
        if (open) {
            Sound.play(settings.sound ?? "");
            response.forceActiveFocus();
        }
    }

    Connections {
        target: PolkitState
        function onAttemptRejected() {
            response.text = "";
            shake.restart();
        }
        function onActionIdChanged() {
            response.text = "";
        }
    }

    SequentialAnimation {
        id: shake
        running: false
        loops: 1
        readonly property int step: Motion.enabled ? 50 : 0
        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -10; duration: shake.step }
        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 10; duration: shake.step }
        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: shake.step }
        NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: shake.step }
    }

    component ActionButton: Rectangle {
        id: button
        required property string label
        property bool primary: false
        signal activated

        implicitWidth: buttonLabel.implicitWidth + Theme.metrics.space.lg * 2
        implicitHeight: 36
        radius: Theme.metrics.radius.medium
        color: primary ? (buttonMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.bg.elevated) : (buttonMouse.containsMouse ? Theme.colors.bg.surface1 : "transparent")
        border.width: 1
        border.color: primary ? Theme.colors.accent.primary : Theme.colors.bg.surface1

        Text {
            id: buttonLabel
            anchors.centerIn: parent
            text: button.label
            color: button.primary && buttonMouse.containsMouse ? Theme.colors.bg.sunken : (button.primary ? Theme.colors.accent.primary : Theme.colors.fg.muted)
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.body
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: button.activated()
        }
    }

    // Scrim: the request is modal, so clicking outside does nothing.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: prompt.open ? 0.6 : 0

        Behavior on opacity {
            MotionAnim {
                spec: prompt.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }

        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: 520
        height: content.implicitHeight + Theme.metrics.space.lg * 2
        radius: panelPlate.shown ? 0 : Theme.metrics.radius.large
        color: panelPlate.shown ? "transparent" : Theme.colors.bg.mantle
        border.width: panelPlate.shown ? 0 : 1
        border.color: prompt.errorText.length > 0 ? Theme.colors.state.danger : Theme.colors.bg.surface1

        PlateFrame {
            id: panelPlate
            role: "panel"
            rule: prompt.errorText.length > 0 ? Theme.colors.state.danger : Theme.colors.accent.primary
        }

        opacity: prompt.open ? 1 : 0
        scale: prompt.open ? 1 : 0.96

        Behavior on opacity {
            MotionAnim {
                spec: prompt.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }
        Behavior on scale {
            MotionAnim {
                spec: prompt.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: prompt.cancel()

            Column {
                id: content
                anchors.top: parent.top
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.metrics.space.lg * 2
                spacing: Theme.metrics.space.md

                Icon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: prompt.settings.icon ?? "lock"
                    size: Math.round(Theme.typography.sizes.heading * 2.4)
                    color: Theme.colors.accent.primary
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: prompt.title
                    color: Theme.colors.accent.primary
                    font.family: Theme.typography.families.display
                    font.pointSize: Math.round(Theme.typography.sizes.heading * 1.15)
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    horizontalAlignment: Text.AlignHCenter
                    text: prompt.epigraph
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                    font.italic: true
                    wrapMode: Text.WordWrap
                }

                // The real request, always shown in full.
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: PolkitState.message
                    color: Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (PolkitState.identity.length > 0 ? prompt.identityLabel + " " + PolkitState.identity + "  ·  " : "") + PolkitState.actionId
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                    elide: Text.ElideMiddle
                }

                Column {
                    width: parent.width
                    spacing: Theme.metrics.space.xs

                    Text {
                        text: PolkitState.prompt.length > 0 ? PolkitState.prompt : "Password:"
                        color: Theme.colors.fg.muted
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.small
                    }

                    Rectangle {
                        width: parent.width
                        height: 44
                        radius: Theme.metrics.radius.medium
                        color: Theme.colors.bg.sunken
                        border.width: 1
                        border.color: response.activeFocus ? Theme.colors.accent.primary : Theme.colors.bg.surface1
                        opacity: PolkitState.responseRequired ? 1 : 0.5

                        TextInput {
                            id: response
                            anchors.fill: parent
                            anchors.leftMargin: Theme.metrics.space.md
                            anchors.rightMargin: Theme.metrics.space.md
                            verticalAlignment: TextInput.AlignVCenter
                            focus: prompt.open
                            enabled: PolkitState.responseRequired
                            echoMode: PolkitState.echo ? TextInput.Normal : TextInput.Password
                            passwordCharacter: prompt.maskCharacter
                            passwordMaskDelay: 0
                            color: Theme.colors.fg.primary
                            selectionColor: Theme.colors.accent.primary
                            selectedTextColor: Theme.colors.bg.sunken
                            font.family: Theme.typography.families.mono
                            font.pointSize: Theme.typography.sizes.body
                            font.letterSpacing: PolkitState.echo ? 0 : 2
                            clip: true
                            Keys.onEscapePressed: prompt.cancel()
                            Keys.onReturnPressed: prompt.submit()
                            Keys.onEnterPressed: prompt.submit()
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: text.length > 0
                    text: prompt.errorText.length > 0 ? prompt.errorText : PolkitState.notice
                    color: prompt.errorText.length > 0 ? Theme.colors.state.danger : Theme.colors.fg.muted
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                    wrapMode: Text.WordWrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: Theme.metrics.space.sm

                    ActionButton {
                        label: prompt.cancelLabel
                        onActivated: prompt.cancel()
                    }

                    ActionButton {
                        label: prompt.submitLabel
                        primary: true
                        onActivated: prompt.submit()
                    }
                }
            }
        }
    }
}
