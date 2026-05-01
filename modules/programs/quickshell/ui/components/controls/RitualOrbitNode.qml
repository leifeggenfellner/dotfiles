import QtQuick
import "../.."

Item {
    id: node

    required property var orbitField
    required property var device

    signal clicked

    readonly property real baseAngle: orbitField ? orbitField._baseAngleFor(device ? device.id : "") : 0
    readonly property real theta: baseAngle + (orbitField ? orbitField.orbitPhase : 0)
    readonly property real depth: (Math.sin(theta) + 1.0) / 2.0

    readonly property bool isFocused: !!(orbitField && device && orbitField.focusedId === device.id)
    readonly property bool _connecting: device && device.state === "connecting"

    readonly property real baseSize: 34 + depth * 16
    readonly property real size: orbitField && orbitField.fieldMode === "focus" && isFocused ? 86 : baseSize
    readonly property real ox: orbitField ? orbitField.centerX + Math.cos(theta) * orbitField.orbitRadius : 0
    readonly property real oy: orbitField ? orbitField.centerY + Math.sin(theta) * orbitField.orbitRadius * orbitField.orbitYScale : 0

    width: size
    height: size
    z: orbitField && orbitField.fieldMode === "focus" ? (isFocused ? 999 : 50 + depth * 40) : (50 + depth * 80)
    x: (orbitField && orbitField.fieldMode === "focus" && isFocused ? orbitField.centerX : ox) - width / 2
    y: (orbitField && orbitField.fieldMode === "focus" && isFocused ? orbitField.centerY : oy) - height / 2

    opacity: {
        if (orbitField && orbitField.fieldMode === "focus" && !isFocused)
            return 0.20 + depth * 0.25;
        return 0.45 + depth * 0.55;
    }

    Behavior on x {
        NumberAnimation {
            duration: orbitField && orbitField.fieldMode === "field" ? 0 : (orbitField ? orbitField.motionDuration : 0)
            easing.type: Easing.OutCubic
        }
    }
    Behavior on y {
        NumberAnimation {
            duration: orbitField && orbitField.fieldMode === "field" ? 0 : (orbitField ? orbitField.motionDuration : 0)
            easing.type: Easing.OutCubic
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: orbitField ? orbitField.motionDuration : 0
            easing.type: Easing.OutCubic
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: orbitField ? orbitField.motionDuration : 0
            easing.type: Easing.OutCubic
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: orbitField ? orbitField.fadeDuration : 0
            easing.type: Easing.OutCubic
        }
    }

    RitualDeviceCard {
        anchors.fill: parent
        device: node.device
        pathwayColor: node.orbitField ? node.orbitField.pathwayColor : Theme.accent
        variant: node.isFocused ? "focused" : "orbit"
        isFocused: node.isFocused
        onClicked: node.clicked()
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: width / 2
        color: "transparent"
        border.width: node._connecting ? 2 : 0
        border.color: node.orbitField ? Qt.rgba(node.orbitField.pathwayColor.r, node.orbitField.pathwayColor.g, node.orbitField.pathwayColor.b, 0.55) : "transparent"
        RotationAnimator on rotation {
            running: node._connecting
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 820
        }
    }
}
