import QtQuick
import Quickshell
import "../../core"

Item {
    id: root

    property bool reveal: false
    property real time: 0
    property bool alignRight: false

    implicitHeight: column.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column

        anchors.right: root.alignRight ? parent.right : undefined
        anchors.horizontalCenter: root.alignRight ? undefined : parent.horizontalCenter
        spacing: 5
        opacity: 0.88
        y: root.reveal ? 0 : 8

        Behavior on y {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.right: root.alignRight ? parent.right : undefined
            anchors.horizontalCenter: root.alignRight ? undefined : parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, Config.clockFormat)
            color: Theme.colors.fg.primary
            opacity: 0.96
            font.family: Config.font
            font.pixelSize: Math.max(68, Math.min(root.width * 0.22, 108))
            font.letterSpacing: 2
            font.weight: Font.Light
        }

        Text {
            anchors.right: root.alignRight ? parent.right : undefined
            anchors.horizontalCenter: root.alignRight ? undefined : parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM").toUpperCase()
            color: Theme.colors.fg.muted
            opacity: root.reveal ? 0.82 : 0.58
            font.family: Config.font
            font.pixelSize: Math.max(12, Math.min(root.width * 0.026, 18))
            font.letterSpacing: 4
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
