import QtQuick
import "../../core"

FocusScope {
    id: root

    property string screenName: ""
    property bool authenticating: false
    property bool success: false
    property int failureNonce: 0
    property string authMessage: ""
    property bool authMessageIsError: false
    property bool secure: false
    property real cursorX: 0
    property real cursorY: 0
    property bool userAwake: false
    property real time: 0
    property real successGlow: 0
    property real failureGlow: 0

    signal submitPassword(string password)

    focus: true

    readonly property real parallaxX: Config.enableParallax ? cursorX * 22 : 0
    readonly property real parallaxY: Config.enableParallax ? cursorY * 14 : 0

    function reveal() {
        userAwake = true;
        idleTimer.restart();
        password.forceInputFocus();
    }

    Keys.onPressed: event => {
        const hadPasswordFocus = password.inputActiveFocus;
        reveal();
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            password.submitNow();
            event.accepted = true;
        } else if (!hadPasswordFocus && event.key === Qt.Key_Backspace) {
            password.backspace();
            event.accepted = true;
        } else if (!hadPasswordFocus && event.text.length > 0 && !(event.modifiers & Qt.ControlModifier) && !(event.modifiers & Qt.AltModifier)) {
            password.appendText(event.text);
            event.accepted = true;
        }
    }

    Component.onCompleted: focusKick.restart()

    Timer {
        id: frameClock
        interval: Math.round(1000 / Config.fpsLimit)
        repeat: true
        running: root.visible && !root.success
        onTriggered: root.time += interval / 1000
    }

    Timer {
        id: focusKick
        interval: 80
        repeat: false
        onTriggered: root.forceActiveFocus()
    }

    Timer {
        id: idleTimer
        interval: 6500
        repeat: false
        onTriggered: {
            if (password.text.length === 0 && !root.authenticating)
                root.userAwake = false;
        }
    }

    onSuccessChanged: if (success)
        successAnim.restart()
    onFailureNonceChanged: failureAnim.restart()

    NumberAnimation {
        id: successAnim
        target: root
        property: "successGlow"
        from: 0
        to: 1
        duration: 720
        easing.type: Easing.OutCubic
    }

    SequentialAnimation {
        id: failureAnim
        NumberAnimation {
            target: root
            property: "failureGlow"
            from: 0
            to: 1
            duration: 120
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "failureGlow"
            to: 0
            duration: 620
            easing.type: Easing.OutSine
        }
    }

    Background {
        anchors.fill: parent
        time: root.time
        parallaxX: root.parallaxX
        parallaxY: root.parallaxY
        running: root.visible
        successGlow: root.successGlow
        failureGlow: root.failureGlow
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: mouse => {
            root.cursorX = (mouse.x / Math.max(1, width) - 0.5) * 2;
            root.cursorY = (mouse.y / Math.max(1, height) - 0.5) * 2;
            root.reveal();
        }
    }

    RitualCircle {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 0.78
        height: width
        time: root.time
        parallaxX: root.parallaxX * -0.22
        parallaxY: root.parallaxY * -0.18
        opacity: 0.30 + root.successGlow * 0.35
        tint: Config.accentColor
        running: root.visible
    }

    Column {
        id: content

        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Math.min(parent.height * 0.025, 28)
        spacing: Math.max(18, Math.round(parent.height * 0.026))
        opacity: root.success ? 0 : 1
        scale: root.success ? 1.04 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: 420
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: 520
                easing.type: Easing.OutCubic
            }
        }

        Clock {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width * 0.84, 900)
            reveal: root.userAwake || password.text.length > 0
            time: root.time
        }

        PasswordField {
            id: password

            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(root.width * 0.34, 420)
            revealed: root.userAwake || text.length > 0 || root.authenticating
            authenticating: root.authenticating
            success: root.success
            failureNonce: root.failureNonce
            message: root.authMessage
            messageIsError: root.authMessageIsError
            enabled: root.secure && !root.success
            onSubmit: value => root.submitPassword(value)
            onKeyPulse: (x, y) => sparks.emitAt(x, y)
        }
    }

    ParticleLayer {
        anchors.fill: parent
        time: root.time
        count: Config.particleCount
        opacityScale: Config.particleOpacity
        accent: Config.accentColor
        parallaxX: root.parallaxX * 0.36
        parallaxY: root.parallaxY * 0.24
        running: root.visible
    }

    ParticleLayer {
        id: sparks

        anchors.fill: parent
        time: root.time
        count: 0
        opacityScale: 0.9
        accent: Config.accentColor
        running: root.visible
        burstMode: true
    }
}
