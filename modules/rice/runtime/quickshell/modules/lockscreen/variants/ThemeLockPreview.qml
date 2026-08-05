import QtQuick
import QtQuick.Window
import Quickshell

Item {
    id: root

    property string themePath: Quickshell.env("RICE_LOCK_THEME_PATH")

    readonly property var sddm: fakeSddm
    readonly property var userModel: fakeUserModel
    readonly property var sessionModel: fakeSessionModel
    readonly property var config: ({})
    readonly property var lockState: sharedLockState
    readonly property QtObject keyboard: QtObject {
        property bool numLock: false
        property bool capsLock: false
    }

    QtObject {
        id: sharedLockState

        property string password: ""
        property bool authPending: false
    }

    QtObject {
        id: fakeSddm
        signal loginFailed
        signal loginSucceeded
        property string hostName: "preview"

        function login(user, password, sessionIndex) {
            console.warn("Lock preview: login suppressed for", user, "session", sessionIndex);
            loginFailed();
        }

        function reboot() {
            console.warn("Lock preview: reboot suppressed");
        }

        function powerOff() {
            console.warn("Lock preview: powerOff suppressed");
        }
    }

    ListModel {
        id: fakeUserModel
        property string lastUser: Quickshell.env("USER") || "traveler"
        property int lastIndex: 0
        function rowCount() {
            return count;
        }
        Component.onCompleted: append({
            name: lastUser,
            realName: lastUser,
            icon: "",
            homeDir: "/home/" + lastUser
        })
    }

    ListModel {
        id: fakeSessionModel
        property int lastIndex: 0
        function rowCount() {
            return count;
        }
        Component.onCompleted: append({
            name: "Preview",
            file: "preview.desktop"
        })
    }

    Window {
        id: previewWindow
        width: 1280
        height: 720
        visible: true
        color: "black"
        title: "Theme lockscreen preview (no session lock)"

        Loader {
            anchors.fill: parent
            source: root.themePath.length > 0 ? "file://" + root.themePath + "/Main.qml" : ""
            onLoaded: item.forceActiveFocus()
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("Lock preview: failed to load", source);
            }
        }
    }
}
