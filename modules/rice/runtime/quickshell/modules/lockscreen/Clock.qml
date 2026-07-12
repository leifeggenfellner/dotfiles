import QtQuick
import Quickshell
import "../../core"

Item {
    id: root

    property bool reveal: false
    property real time: 0

    implicitHeight: column.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column

        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        opacity: 0.92
        y: root.reveal ? 0 : 8

        Behavior on y {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, Config.clockFormat)
            color: Theme.colors.fg.primary
            opacity: 0.96
            font.family: Config.font
            font.pixelSize: Math.max(78, Math.min(root.width * 0.17, 164))
            font.weight: Font.Light
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.colors.fg.muted
            opacity: root.reveal ? 0.82 : 0.58
            font.family: Theme.typography.families.sans
            font.pixelSize: Math.max(15, Math.min(root.width * 0.032, 28))
            font.weight: Font.Normal

            Behavior on opacity {
                NumberAnimation {
                    duration: 380
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
