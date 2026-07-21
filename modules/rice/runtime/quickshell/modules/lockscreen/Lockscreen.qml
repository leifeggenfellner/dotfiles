import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Item {
    id: root

    property string pendingResponse: ""
    property bool success: false
    property bool releasing: false
    property int failureNonce: 0
    readonly property bool authenticating: pam.active
    readonly property string authMessage: pam.message
    readonly property bool authMessageIsError: pam.messageIsError

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

    function answerIfReady() {
        if (root.pendingResponse.length > 0 && pam.responseRequired) {
            pam.respond(root.pendingResponse);
            root.pendingResponse = "";
        }
    }

    function fail() {
        root.pendingResponse = "";
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
                    authMessage: root.authMessage
                    authMessageIsError: root.authMessageIsError
                    secure: sessionLock.secure
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
