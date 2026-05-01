import QtQuick
import "../../../" as Ui

Item {
    id: pwd

    required property color pathwayColor
    required property string deviceName
    property alias password: input.text
    property bool autoFocus: true

    signal submitted(string password)
    signal cancelled

    implicitHeight: 66

    function focusInput() {
        input.forceActiveFocus();
    }

    function clear() {
        input.text = "";
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Qt.rgba(Ui.Theme.base.r, Ui.Theme.base.g, Ui.Theme.base.b, 0.66)
        border.width: 1
        border.color: Qt.rgba(Ui.Theme.surface1.r, Ui.Theme.surface1.g, Ui.Theme.surface1.b, 0.45)

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            Text {
                text: pwd.deviceName.length > 0 ? ("Password - " + pwd.deviceName) : "Password"
                font {
                    family: Ui.Theme.fontMono
                    pixelSize: 9
                }
                color: Qt.rgba(Ui.Theme.subtext0.r, Ui.Theme.subtext0.g, Ui.Theme.subtext0.b, 0.8)
            }

            Rectangle {
                width: parent.width
                height: 28
                radius: 6
                color: Qt.rgba(Ui.Theme.surface0.r, Ui.Theme.surface0.g, Ui.Theme.surface0.b, 0.72)
                border.width: 1
                border.color: Qt.rgba(pwd.pathwayColor.r, pwd.pathwayColor.g, pwd.pathwayColor.b, 0.35)

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.margins: 6
                    echoMode: TextInput.Password
                    color: Ui.Theme.text
                    selectionColor: Qt.rgba(pwd.pathwayColor.r, pwd.pathwayColor.g, pwd.pathwayColor.b, 0.45)
                    font {
                        family: Ui.Theme.fontMono
                        pixelSize: 11
                    }
                    onAccepted: pwd.submitted(text)
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible && autoFocus)
            focusInput();
    }

    Component.onCompleted: {
        if (visible && autoFocus)
            focusInput();
    }
}
