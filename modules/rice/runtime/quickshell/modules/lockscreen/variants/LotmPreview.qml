import QtQuick
import QtQuick.Window
import Quickshell

Item {
    id: root

    property string themePath: Quickshell.env("RICE_LOCK_LOTM_THEME_PATH")

    readonly property var sddm: fakeSddm
    readonly property var userModel: fakeUserModel
    readonly property var sessionModel: fakeSessionModel
    readonly property var config: ({})
    readonly property QtObject keyboard: QtObject {
        property bool numLock: false
        property bool capsLock: false
    }

    QtObject {
        id: fakeSddm
        signal loginFailed
        signal loginSucceeded
        property string hostName: "preview"

        function login(user, password, sessionIndex) {
            console.warn("LotmPreview: login suppressed for", user, "session", sessionIndex);
            loginFailed();
        }

        function reboot() {
            console.warn("LotmPreview: reboot suppressed");
        }

        function powerOff() {
            console.warn("LotmPreview: powerOff suppressed");
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
        title: "LOTM lockscreen preview (no session lock)"

        Loader {
            anchors.fill: parent
            source: root.themePath.length > 0 ? "file://" + root.themePath + "/Main.qml" : ""
            onLoaded: item.forceActiveFocus()
            onStatusChanged: {
                if (status === Loader.Error)
                    console.error("LotmPreview: failed to load", source);
            }
        }
    }
}
