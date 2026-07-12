import QtQuick
import "../../core"

Item {
    id: root

    property real time: 0
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true

    readonly property string fallbackImage: Theme.wallpapers.length > 0 ? "file://" + Theme.wallpapers[0] : ""
    readonly property string sourceUrl: Config.imagePath.length > 0 ? Config.imagePath : fallbackImage

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
    }

    Image {
        id: base

        anchors.fill: parent
        anchors.margins: -48
        source: root.sourceUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: status === Image.Ready ? 1 : 0
        x: -root.parallaxX * 0.34
        y: -root.parallaxY * 0.26
        scale: 1.055 + Math.sin(root.time * 0.22) * 0.006

        Behavior on opacity {
            NumberAnimation {
                duration: 900
                easing.type: Easing.OutCubic
            }
        }
    }

    Image {
        anchors.fill: parent
        anchors.margins: -96
        source: root.sourceUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        opacity: base.opacity * 0.20
        x: root.parallaxX * 0.18 + Math.sin(root.time * 0.08) * 10
        y: root.parallaxY * 0.16 + Math.cos(root.time * 0.07) * 8
        scale: 1.12
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: 0.35
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.22
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.colors.bg.base
            }
            GradientStop {
                position: 0.46
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: Theme.colors.bg.sunken
            }
        }
    }
}
