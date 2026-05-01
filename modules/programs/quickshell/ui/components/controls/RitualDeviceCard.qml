import QtQuick
import QtQuick.Layouts
import "../.."

Item {
    id: card

    required property var device
    property color pathwayColor: Theme.accent
    property string variant: "row"
    property bool isFocused: false
    property bool showLockBadge: true
    property bool showSubtitle: true

    signal clicked

    readonly property string _state: device ? device.state : "idle"
    readonly property real _signal: device ? Number(device.signal || 0.0) : 0.0
    readonly property bool _connected: _state === "connected"
    readonly property bool _connecting: _state === "connecting"
    readonly property bool _error: _state === "error"
    readonly property bool _secured: device ? !!device.secured : false
    readonly property string _type: device ? (device.type || "") : ""

    readonly property bool _isCircle: variant === "orbit" || variant === "focused"

    implicitWidth: {
        if (variant === "row")
            return parent ? parent.width : 320;
        if (variant === "tile")
            return 110;
        return 0;
    }
    implicitHeight: {
        if (variant === "row")
            return 44;
        if (variant === "tile")
            return 56;
        return 0;
    }

    function _wifiSignalIcon(sig) {
        if (sig >= 0.80)
            return "󰤨";
        if (sig >= 0.60)
            return "󰤥";
        if (sig >= 0.40)
            return "󰤢";
        if (sig >= 0.20)
            return "󰤟";
        return "󰤯";
    }

    readonly property string _iconGlyph: {
        if (_type === "bluetooth")
            return _connected ? "󰂱" : "󰂯";
        if (_type === "ethernet")
            return _connected ? "󰈁" : "󰈀";
        if (_type === "wifi")
            return _wifiSignalIcon(_signal);
        return "󰛳";
    }

    readonly property string _subtitleText: {
        if (_connecting)
            return "connecting…";
        if (_connected)
            return "connected";
        if (_error)
            return "failed";
        if (_type === "ethernet")
            return "disconnected";
        if (_type === "wifi")
            return _secured ? "secured" : "open";
        if (_type === "bluetooth")
            return device && device.paired ? "paired" : "available";
        return "";
    }

    readonly property color _iconColor: _connected || isFocused ? pathwayColor : _error ? Qt.rgba(0.9, 0.3, 0.3, 1) : Theme.subtext0

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: card._isCircle ? Math.min(width, height) / 2 : (card.variant === "tile" ? 8 : 8)

        color: {
            if (card._connected)
                return Qt.rgba(card.pathwayColor.r, card.pathwayColor.g, card.pathwayColor.b, card._isCircle ? 0.30 : 0.12);
            if (card._error)
                return Qt.rgba(0.92, 0.30, 0.30, card._isCircle ? 0.36 : 0.10);
            if (card._isCircle)
                return Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.72);
            if (_hover.containsMouse)
                return Qt.rgba(Theme.surface0.r, Theme.surface0.g, Theme.surface0.b, 0.55);
            return Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, card.variant === "row" ? 0.60 : 0.70);
        }
        border.width: 1
        border.color: {
            if (card._error)
                return Qt.rgba(0.92, 0.30, 0.30, 0.72);
            if (card._connected || card.isFocused)
                return Qt.rgba(card.pathwayColor.r, card.pathwayColor.g, card.pathwayColor.b, card._isCircle ? 0.72 : 0.45);
            if (!card._isCircle && _hover.containsMouse)
                return Qt.rgba(Theme.surface2.r, Theme.surface2.g, Theme.surface2.b, 0.65);
            return Qt.rgba(Theme.surface1.r, Theme.surface1.g, Theme.surface1.b, card.variant === "row" ? 0.30 : 0.40);
        }

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Theme.animDurationFast
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: card.variant === "row"
        sourceComponent: rowLayout
    }

    Loader {
        anchors.fill: parent
        active: card.variant === "tile"
        sourceComponent: tileLayout
    }

    Text {
        visible: card._isCircle
        anchors.centerIn: parent
        text: card._iconGlyph
        font.family: Theme.fontMono
        font.pixelSize: Math.max(14, parent.width * 0.42)
        color: card._iconColor
    }

    Rectangle {
        id: lockBadge
        visible: card.showLockBadge && card._secured && !card._connected && card._type === "wifi" && card._isCircle
        width: 16
        height: 16
        radius: 8
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -4
        anchors.topMargin: -4
        color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, 0.92)
        border.width: 1
        border.color: Qt.rgba(card.pathwayColor.r, card.pathwayColor.g, card.pathwayColor.b, 0.55)

        Text {
            anchors.centerIn: parent
            text: "󰌾"
            font {
                family: Theme.fontMono
                pixelSize: 9
            }
            color: card.pathwayColor
        }
    }

    Text {
        visible: card._isCircle && card._type === "wifi"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 4
        text: card.device ? (card.device.name || "") : ""
        font.family: Theme.fontMono
        font.pixelSize: 9
        color: card._connected ? card.pathwayColor : Theme.text
        elide: Text.ElideRight
        width: 112
        horizontalAlignment: Text.AlignHCenter
    }

    MouseArea {
        id: _hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }

    Component {
        id: rowLayout
        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            Text {
                text: card._iconGlyph
                font {
                    family: Theme.fontMono
                    pixelSize: 14
                }
                color: card._iconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: card.device ? (card.device.name || "") : ""
                    font {
                        family: Theme.fontMono
                        pixelSize: 11
                        weight: Font.Medium
                    }
                    color: Theme.text
                }

                Text {
                    visible: card.showSubtitle
                    text: card._subtitleText
                    font {
                        family: Theme.fontMono
                        pixelSize: 9
                    }
                    color: card._connected ? Qt.rgba(card.pathwayColor.r, card.pathwayColor.g, card.pathwayColor.b, 0.75) : Qt.rgba(Theme.subtext0.r, Theme.subtext0.g, Theme.subtext0.b, 0.60)
                }
            }
        }
    }

    Component {
        id: tileLayout
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            Text {
                text: card._iconGlyph
                font {
                    family: Theme.fontMono
                    pixelSize: 14
                }
                color: card._iconColor
                Layout.alignment: Qt.AlignVCenter
            }

            Column {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    width: parent.width
                    text: card.device ? (card.device.name || "") : ""
                    font {
                        family: Theme.fontMono
                        pixelSize: 11
                        weight: Font.Medium
                    }
                    color: card._connected ? Theme.text : Theme.subtext1
                    elide: Text.ElideRight
                }

                Text {
                    visible: card.showSubtitle
                    width: parent.width
                    text: card._subtitleText
                    font {
                        family: Theme.fontMono
                        pixelSize: 9
                    }
                    color: card._connected ? Qt.rgba(card.pathwayColor.r, card.pathwayColor.g, card.pathwayColor.b, 0.75) : card._error ? Qt.rgba(0.9, 0.3, 0.3, 0.85) : Qt.rgba(Theme.subtext0.r, Theme.subtext0.g, Theme.subtext0.b, 0.65)
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: card.showLockBadge && card._secured && card._type === "wifi"
                text: "󰌾"
                font {
                    family: Theme.fontMono
                    pixelSize: 10
                }
                color: Qt.rgba(Theme.subtext0.r, Theme.subtext0.g, Theme.subtext0.b, 0.55)
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

}
