import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: ctx

    property string windowTitle: ""
    property int maxLength: 40

    Layout.preferredHeight: parent.height
    Layout.preferredWidth: label.implicitWidth + 16

    Text {
        id: label
        anchors.centerIn: parent
        text: ctx.formatTitle(ctx.windowTitle)
        color: Theme.subtext0
        font {
            family: Theme.fontMono
            pixelSize: Theme.fontSizeSmall
        }
        elide: Text.ElideRight
        maximumLineCount: 1

        Behavior on text {
            enabled: false // avoid animation on text change
        }

        opacity: text.length > 0 ? 0.8 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: Theme.animDurationFast }
        }
    }

    function formatTitle(title) {
        if (!title) return "";
        // Strip common suffixes like " - App Name"
        let cleaned = title.replace(/ [-–—] [^-–—]+$/, "");
        if (cleaned.length > maxLength) {
            cleaned = cleaned.substring(0, maxLength - 1) + "…";
        }
        return cleaned;
    }
}
