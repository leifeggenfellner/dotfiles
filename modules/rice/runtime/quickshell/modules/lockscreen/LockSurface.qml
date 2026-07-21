import QtQuick
import "../../core"

FocusScope {
    id: root

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

    readonly property bool compactLayout: width < 920
    readonly property real sideMargin: compactLayout ? Math.max(26, width * 0.06) : Math.max(64, Math.min(width * 0.085, 128))
    readonly property real topMargin: compactLayout ? Math.max(64, height * 0.09) : Math.max(76, height * 0.09)
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
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: root.compactLayout ? parent.horizontalCenter : parent.left
        anchors.horizontalCenterOffset: root.compactLayout ? 0 : parent.width * 0.31
        width: Math.min(parent.width, parent.height) * (root.compactLayout ? 0.70 : 0.86)
        height: width
        time: root.time
        parallaxX: root.parallaxX * -0.22
        parallaxY: root.parallaxY * -0.18
        opacity: 0.22 + root.successGlow * 0.30
        tint: Config.accentColor
        running: root.visible
    }

    Item {
        id: clockCluster

        width: root.compactLayout ? root.width - root.sideMargin * 2 : Math.min(root.width * 0.30, 430)
        height: clock.implicitHeight + 48
        anchors.top: parent.top
        anchors.topMargin: root.topMargin
        anchors.right: root.compactLayout ? undefined : parent.right
        anchors.rightMargin: root.sideMargin
        anchors.horizontalCenter: root.compactLayout ? parent.horizontalCenter : undefined
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
            id: clock

            width: parent.width - 34
            x: root.compactLayout ? (parent.width - width) / 2 : 0
            alignRight: !root.compactLayout
            reveal: root.userAwake || password.text.length > 0
            time: root.time
        }
    }

    Column {
        id: loginForm

        anchors.left: root.compactLayout ? undefined : parent.left
        anchors.leftMargin: root.compactLayout ? 0 : root.sideMargin
        anchors.horizontalCenter: root.compactLayout ? parent.horizontalCenter : undefined
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.compactLayout ? Math.max(62, root.height * 0.09) : Math.max(72, root.height * 0.075)
        width: root.compactLayout ? Math.min(root.width - root.sideMargin * 2, 310) : 292
        opacity: root.success ? 0 : 1
        scale: root.success ? 1.02 : 1

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

        PasswordField {
            id: password

            width: parent.width
            revealed: root.userAwake || text.length > 0 || root.authenticating
            authenticating: root.authenticating
            success: root.success
            failureNonce: root.failureNonce
            message: root.authMessage
            messageIsError: root.authMessageIsError
            enabled: root.secure && !root.success
            alignRight: false
            onSubmit: value => root.submitPassword(value)
            onKeyPulse: (x, y) => sparks.emitAt(x + loginForm.x + password.x, y + loginForm.y + password.y)
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
