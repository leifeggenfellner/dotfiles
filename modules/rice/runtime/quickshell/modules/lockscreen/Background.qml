import QtQuick
import "../../core"

Item {
    id: root

    property real time: 0
    property real parallaxX: 0
    property real parallaxY: 0
    property bool running: true
    property real successGlow: 0
    property real failureGlow: 0

    readonly property bool useVideo: Config.backgroundMode === "video" && Config.videoPath.length > 0

    Loader {
        anchors.fill: parent
        active: true
        sourceComponent: root.useVideo ? videoComponent : imageComponent
    }

    Component {
        id: videoComponent
        VideoBackground {
            time: root.time
            parallaxX: root.parallaxX
            parallaxY: root.parallaxY
            running: root.running
        }
    }

    Component {
        id: imageComponent
        ImageBackground {
            time: root.time
            parallaxX: root.parallaxX
            parallaxY: root.parallaxY
            running: root.running
        }
    }

    FogLayer {
        anchors.fill: parent
        time: root.time
        tint: Config.accentColor
        strength: Config.fogOpacity
        parallaxX: root.parallaxX * 0.52
        parallaxY: root.parallaxY * 0.36
        running: root.running
    }

    ShaderEffects {
        anchors.fill: parent
        time: root.time
        successGlow: root.successGlow
        failureGlow: root.failureGlow
        running: root.running
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.state.danger
        opacity: root.failureGlow * 0.13
    }

    Rectangle {
        anchors.fill: parent
        color: Config.accentColor
        opacity: root.successGlow * 0.10
    }
}
