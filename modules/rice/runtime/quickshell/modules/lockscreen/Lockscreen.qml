import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Item {
    id: root

    property string pendingResponse: ""
    property string password: ""
    property bool success: false
    property bool releasing: false
    property int failureNonce: 0
    property bool authFailed: false
    property string errorMessage: ""
    readonly property bool authenticating: pam.active
    readonly property string authMessage: root.errorMessage.length > 0 ? root.errorMessage : pam.message
    readonly property bool authMessageIsError: root.authFailed || pam.messageIsError

    function submit(password) {
        if (password.length === 0 || root.success || root.releasing || !sessionLock.secure)
            return;

        if (pam.active)
            pam.abort();

        root.pendingResponse = password;
        if (!pam.start()) {
            root.fail();
            return;
        }
        root.answerIfReady();
    }

    function setPassword(value) {
        if (!root.authenticating && !root.success && !root.releasing) {
            if (root.authFailed && value.length > root.password.length)
                root.clearError();
            root.password = value;
        }
    }

    function clearError() {
        root.authFailed = false;
        root.errorMessage = "";
    }

    function answerIfReady() {
        if (root.pendingResponse.length > 0 && pam.responseRequired) {
            pam.respond(root.pendingResponse);
            root.pendingResponse = "";
        }
    }

    function fail() {
        root.pendingResponse = "";
        root.password = "";
        root.authFailed = true;
        root.errorMessage = "ACCESS DENIED";
        root.failureNonce += 1;
    }

    function finish() {
        if (root.releasing)
            return;
        root.releasing = true;
        sessionLock.locked = false;
        releaseTimer.restart();
    }

    WlSessionLock {
        id: sessionLock

        locked: true
        surface: Component {
            WlSessionLockSurface {
                id: lockSurface

                color: "transparent"

                LockSurface {
                    anchors.fill: parent
                    authenticating: root.authenticating
                    success: root.success || root.releasing
                    failureNonce: root.failureNonce
                    passwordText: root.password
                    authMessage: root.authMessage
                    authMessageIsError: root.authMessageIsError
                    secure: sessionLock.secure
                    onPasswordTextChangeRequested: value => root.setPassword(value)
                    onSubmitPassword: password => root.submit(password)
                }
            }
        }
    }

    PamContext {
        id: pam

        config: Config.pamService
        user: Quickshell.env("USER") || ""
        onResponseRequiredChanged: root.answerIfReady()
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.clearError();
                root.success = true;
                finishTimer.restart();
            } else {
                root.fail();
            }
        }
        onError: error => root.fail()
    }

    Timer {
        id: finishTimer
        interval: 760
        repeat: false
        onTriggered: root.finish()
    }

    Timer {
        id: releaseTimer
        interval: 340
        repeat: false
        onTriggered: Qt.quit()
    }
}
