import QtQuick
import QtQuick.Layouts

Item {
    id: sysPlaceholders

    Layout.preferredHeight: parent.height

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.barSpacing

        // Volume placeholder
        Text {
            text: "󰕾"
            color: Theme.subtext1
            font {
                family: Theme.fontMono
                pixelSize: Theme.fontSizeIcon
            }
            opacity: 0.6
        }

        // Network placeholder
        Text {
            text: "󰤨"
            color: Theme.subtext1
            font {
                family: Theme.fontMono
                pixelSize: Theme.fontSizeIcon
            }
            opacity: 0.6
        }
    }
}
