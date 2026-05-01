import QtQuick
import QtQuick.Layouts

Item {
    id: clock

    Layout.preferredHeight: parent.height

    property string timeStr: ""

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            let now = new Date();
            clock.timeStr = Qt.formatTime(now, "HH:mm");
        }
    }

    Text {
        anchors.centerIn: parent
        text: clock.timeStr
        color: Theme.text
        font {
            family: Theme.fontMono
            pixelSize: Theme.fontSizeBar
            weight: Font.DemiBold
            letterSpacing: 1
        }
    }
}
