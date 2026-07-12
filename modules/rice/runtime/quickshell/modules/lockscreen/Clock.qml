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
        spacing: 8
        opacity: 0.92
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
            font.pixelSize: Math.max(92, Math.min(root.width * 0.30, 184))
            font.weight: Font.Light
        }

        Row {
            anchors.right: root.alignRight ? parent.right : undefined
            anchors.horizontalCenter: root.alignRight ? undefined : parent.horizontalCenter
            spacing: 10

            Repeater {
                model: 5

                Rectangle {
                    required property int index
                    width: index === 2 ? 42 : 18
                    height: 1
                    color: Config.accentColor
                    opacity: index === 2 ? 0.58 : 0.28
                }
            }
        }

        Text {
            anchors.right: root.alignRight ? parent.right : undefined
            anchors.horizontalCenter: root.alignRight ? undefined : parent.horizontalCenter
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
