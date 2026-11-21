import QtQuick
import "../core"

// ── PasswordPrompt ────────────────────────────────────────────
// An inline secret field. Enter submits, Esc cancels, the eye shows
// what was typed. Takes focus when it appears.

FocusScope {
    id: root

    property string placeholder: "Password"
    property string note: ""
    property bool reveal: false

    signal submitted(string secret)
    signal cancelled

    implicitHeight: column.implicitHeight

    onVisibleChanged: if (visible) {
        field.text = "";
        reveal = false;
        field.forceActiveFocus();
    }
    Component.onCompleted: if (visible)
        field.forceActiveFocus()

    Column {
        id: column
        width: parent.width
        spacing: 2

        Text {
            visible: root.note.length > 0
            text: root.note
            color: Theme.colors.state.warn
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }

        Rectangle {
            width: parent.width
            height: 34
            radius: Theme.metrics.radius.small
            color: Theme.colors.bg.sunken
            border.width: field.activeFocus ? 2 : 1
            border.color: field.activeFocus ? Theme.colors.accent.primary : Theme.colors.bg.surface1

            TextInput {
                id: field
                anchors.left: parent.left
                anchors.right: eye.left
                anchors.leftMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                echoMode: root.reveal ? TextInput.Normal : TextInput.Password
                color: Theme.colors.fg.primary
                selectionColor: Theme.colors.accent.primary
                selectedTextColor: Theme.colors.bg.sunken
                clip: true
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.body
                focus: true
                onAccepted: if (text.length > 0)
                    root.submitted(text)
                Keys.onEscapePressed: root.cancelled()

                Text {
                    visible: field.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder + " · Enter to join"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }

            Icon {
                id: eye
                anchors.right: parent.right
                anchors.rightMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                name: root.reveal ? "eye-off" : "eye"
                size: Theme.typography.sizes.body
                color: eyeMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle

                MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.metrics.space.xs
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.reveal = !root.reveal
                }
            }
        }
    }
}
