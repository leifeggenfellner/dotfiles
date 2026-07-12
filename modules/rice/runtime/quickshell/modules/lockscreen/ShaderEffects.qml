import QtQuick
import "../../core"
import "../../components/effects"

Item {
    id: root

    property real time: 0
    property real successGlow: 0
    property real failureGlow: 0
    property bool running: true

    ShaderSurface {
        anchors.fill: parent
        visible: Config.enableShaders
        shaderName: "lock-veil"
        tint: Config.accentColor
        strength: 0.46 + Config.blurStrength * 0.006
        speed: 1.0
        time: root.time
        progress: root.successGlow
        bandStart: 0
        bandEnd: 1
    }

    Item {
        anchors.fill: parent
        visible: !Config.enableShaders

        Repeater {
            model: 4

            Rectangle {
                required property int index
                width: parent.width * (0.18 + index * 0.045)
                height: parent.height * 1.4
                x: parent.width * (0.12 + index * 0.20) + Math.sin(root.time * 0.08 + index) * 38
                y: -parent.height * 0.18
                rotation: -18 + index * 4
                color: Config.accentColor
                opacity: 0.025 + index * 0.007
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.32
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.colors.bg.sunken
            }
            GradientStop {
                position: 0.38
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: Theme.colors.bg.sunken
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: 0.18 + root.failureGlow * 0.12
    }
}
