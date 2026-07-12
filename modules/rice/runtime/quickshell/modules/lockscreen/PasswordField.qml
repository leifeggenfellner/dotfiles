import QtQuick
import "../../core"

Item {
    id: root

    property bool revealed: false
    property bool authenticating: false
    property bool success: false
    property int failureNonce: 0
    property string message: ""
    property bool messageIsError: false
    property real failAmount: 0
    property alias text: input.text
    readonly property bool inputActiveFocus: input.activeFocus

    signal submit(string value)
    signal keyPulse(real x, real y)

    implicitHeight: 68
    opacity: shown ? 1 : 0
    y: shown ? 0 : 18
    scale: shown ? 1 : 0.985

    readonly property bool shown: revealed || input.text.length > 0 || input.activeFocus

    function forceInputFocus() {
        input.forceActiveFocus();
    }

    function appendText(value) {
        input.text += value;
        input.cursorPosition = input.text.length;
        keyPulse(input.width * 0.5, input.height * 0.5);
    }

    function backspace() {
        if (input.text.length > 0)
            input.text = input.text.slice(0, input.text.length - 1);
    }

    function clear() {
        input.text = "";
    }

    function submitNow() {
        if (input.text.length > 0 && !authenticating)
            submit(input.text);
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 360
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: 420
            easing.type: Easing.OutCubic
        }
    }
    Behavior on scale {
        NumberAnimation {
            duration: 420
            easing.type: Easing.OutCubic
        }
    }

    onFailureNonceChanged: {
        clear();
        failPulse.restart();
    }

    Rectangle {
        id: aura

        anchors.fill: field
        anchors.margins: -16
        radius: height / 2
        color: root.messageIsError ? Theme.colors.state.danger : Config.accentColor
        opacity: (input.activeFocus ? 0.10 : 0.045) + root.failAmount * 0.08
        scale: input.activeFocus ? 1.02 : 0.96

        Behavior on opacity {
            NumberAnimation {
                duration: 220
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: field

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 46
        radius: 8
        color: Theme.colors.bg.mantle
        opacity: 0.62
        border.width: 1
        border.color: root.messageIsError ? Theme.colors.state.danger : Config.accentColor
    }

    TextInput {
        id: input

        anchors.fill: field
        anchors.leftMargin: 22
        anchors.rightMargin: 22
        color: Theme.colors.fg.primary
        selectionColor: Config.accentColor
        selectedTextColor: Theme.colors.bg.sunken
        echoMode: TextInput.Password
        passwordCharacter: "*"
        font.family: Theme.typography.families.mono
        font.pixelSize: 20
        horizontalAlignment: TextInput.AlignHCenter
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        enabled: root.enabled && !root.authenticating && !root.success
        onTextEdited: root.keyPulse(width * 0.5 + (cursorPosition - text.length / 2) * 8, height * 0.5)
        Keys.onReturnPressed: root.submitNow()
        Keys.onEnterPressed: root.submitNow()
    }

    Rectangle {
        anchors.left: field.left
        anchors.right: field.right
        anchors.top: field.bottom
        anchors.topMargin: 8
        height: 1
        color: root.messageIsError ? Theme.colors.state.danger : Config.accentColor
        opacity: input.activeFocus ? 0.86 : 0.34
    }

    Text {
        anchors.top: field.bottom
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        text: root.authenticating ? "..." : root.message
        visible: text.length > 0
        color: root.messageIsError ? Theme.colors.state.danger : Theme.colors.fg.subtle
        opacity: 0.86
        font.family: Theme.typography.families.sans
        font.pixelSize: 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    SequentialAnimation {
        id: failPulse
        NumberAnimation {
            target: root
            property: "failAmount"
            from: 0
            to: 1
            duration: 110
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "failAmount"
            to: 0
            duration: 520
            easing.type: Easing.OutSine
        }
    }
}
