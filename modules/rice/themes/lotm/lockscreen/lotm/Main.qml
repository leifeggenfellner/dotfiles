import QtQuick
import QtQuick.Shapes
import Qt5Compat.GraphicalEffects
import QtMultimedia
import Qt.labs.folderlistmodel
import Quickshell

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "transparent"
    readonly property real s: height / 1080

    // LOTM theme integration. Values default to the lockscreen's native
    // palette; the rice-lock-screen launcher exports RICE_LOTM_LOCK_*
    // from the active theme manifest when variant=lotm.
    function _env(name, fallback) {
        const v = Quickshell.env(name);
        return v && String(v).length > 0 ? String(v) : fallback;
    }

    // Wayland Cursor Fix
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        z: -1
    }

    // Colors — env-driven with native LOTM fallbacks.
    readonly property color fg: _env("RICE_LOTM_LOCK_FG", "#fdfaf2")
    readonly property color gold: _env("RICE_LOTM_LOCK_ACCENT", "#c9a063")
    readonly property color goldDim: _env("RICE_LOTM_LOCK_ACCENT_DIM", "#8c6d45")
    readonly property color orbitClr: _env("RICE_LOTM_LOCK_ORBIT", "#ffffff")

    // Polish switches.
    // - RICE_LOTM_LOCK_FONT_FAMILY: swap the bundled Cinzel-Bold for a system family.
    // - RICE_LOTM_LOCK_POWER_ROW=off: hide REBOOT/SHUTDOWN (rice dashboard already exposes these).
    // - RICE_LOTM_LOCK_OVERLAY=on: composite a subtle accent-tinted fog above the video, under the UI.
    readonly property string _fontFamily: {
        const override = _env("RICE_LOTM_LOCK_FONT_FAMILY", "");
        return override.length > 0 ? override : serifFont.name;
    }
    readonly property bool _powerRowVisible: {
        const v = _env("RICE_LOTM_LOCK_POWER_ROW", "on").toLowerCase();
        return ["off", "0", "false", "no", "hide"].indexOf(v) < 0;
    }
    readonly property bool _overlayEnabled: {
        const v = _env("RICE_LOTM_LOCK_OVERLAY", "off").toLowerCase();
        return ["on", "1", "true", "yes"].indexOf(v) >= 0;
    }

    // Quickshell
    property bool isQuickshell: typeof sddm === "undefined" || sddm.hostName === undefined
    readonly property bool _hasSharedLockState: typeof lockState !== "undefined" && lockState !== null
    readonly property string passwordText: root._hasSharedLockState ? lockState.password : root.localPasswordText

    // State
    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property bool sessionMenuOpen: false
    property bool userMenuOpen: false
    property string localPasswordText: ""
    property bool localAuthPending: false
    property bool authPending: root._hasSharedLockState ? lockState.authPending : root.localAuthPending
    property bool localAuthFailed: false
    property string localErrorMessage: ""
    readonly property bool authFailed: root._hasSharedLockState ? lockState.authFailed : root.localAuthFailed
    readonly property string errorMessage: root._hasSharedLockState ? lockState.errorMessage : root.localErrorMessage

    function setPasswordText(value) {
        if (!root.authPending && root.authFailed && value.length > root.passwordText.length)
            root.clearError();
        if (root._hasSharedLockState)
            lockState.password = value;
        else {
            root.localPasswordText = value;
            passInput.text = value;
        }
    }

    function setAuthPending(value) {
        if (root._hasSharedLockState)
            lockState.authPending = value;
        else
            root.localAuthPending = value;
    }

    function setErrorMessage(value) {
        if (root._hasSharedLockState) {
            lockState.authFailed = value.length > 0;
            lockState.errorMessage = value;
        } else {
            root.localAuthFailed = value.length > 0;
            root.localErrorMessage = value;
        }
    }

    function clearError() {
        root.setErrorMessage("");
    }

    function refocusPasswordInput() {
        passInput.forceActiveFocus();
        passInput.cursorPosition = root.passwordText.length;
    }

    FolderListModel {
        id: fontFolder
        folder: Qt.resolvedUrl("font")
        nameFilters: ["*.ttf", "*.otf"]
    }

    FontLoader {
        id: serifFont
        source: fontFolder.count > 0 ? "font/" + fontFolder.get(0, "fileName") : ""
    }

    // Helpers
    ListView {
        id: sessionHelper
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string sName: model.name || ""
        }
    }

    ListView {
        id: userHelper
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        opacity: 0
        width: 1
        height: 1
        z: -100
        delegate: Item {
            property string uName: model.realName || model.name || ""
            property string uLogin: model.name || ""
        }
    }

    // Background
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        z: -1000
    }

    // Prefer the active theme's lockscreen video (rice manifest
    // -> RICE_LOCK_VIDEO), then a LOTM-specific override. If no video
    // is available, rice-lock-screen exports RICE_LOCK_IMAGE.
    readonly property string _bgSource: {
        const v = _env("RICE_LOCK_VIDEO", _env("RICE_LOTM_LOCK_BG", ""));
        if (v.length === 0)
            return "";
        return v.startsWith("file://") || v.indexOf("://") > 0 ? v : "file://" + v;
    }
    readonly property string _fallbackImageSource: {
        const v = _env("RICE_LOCK_IMAGE", "");
        if (v.length === 0)
            return "";
        return v.startsWith("file://") || v.indexOf("://") > 0 ? v : "file://" + v;
    }

    Image {
        anchors.fill: parent
        source: root._fallbackImageSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        visible: root._fallbackImageSource.length > 0
        z: -600
    }

    MediaPlayer {
        id: player
        source: root._bgSource
        videoOutput: bgVideo
        loops: MediaPlayer.Infinite
        Component.onCompleted: if (root._bgSource.length > 0)
            player.play()
    }

    VideoOutput {
        id: bgVideo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
        visible: root._bgSource.length > 0
        z: -500
    }

    Rectangle {
        anchors.fill: parent
        z: -300
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#45000000"
            }
            GradientStop {
                position: 1.0
                color: "#75000000"
            }
        }
    }

    // Phase 4: subtle rice atmosphere layered over the video. Two
    // slow-drifting accent-tinted bands, negligible cost, off by
    // default. z sits above the video/gradient (-300) but below UI.
    Item {
        id: riceOverlay
        anchors.fill: parent
        z: -200
        visible: root._overlayEnabled

        property real t: 0
        NumberAnimation on t {
            from: 0
            to: Math.PI * 2
            duration: 24000
            loops: Animation.Infinite
            running: riceOverlay.visible
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.34
            opacity: 0.16 + 0.04 * Math.sin(riceOverlay.t)
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(root.gold.r, root.gold.g, root.gold.b, 0.28)
                }
                GradientStop {
                    position: 1.0
                    color: "#00000000"
                }
            }
        }
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * 0.42
            opacity: 0.18 + 0.05 * Math.cos(riceOverlay.t * 0.75)
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(root.orbitClr.r, root.orbitClr.g, root.orbitClr.b, 0.18)
                }
            }
        }
    }

    // Clock
    Item {
        id: clockWidget
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.top: parent.top
        anchors.topMargin: 100 * s
        width: 450 * s
        height: 250 * s

        Item {
            id: orbitalSpace
            anchors.centerIn: timeLabels
            width: 320 * s
            height: 100 * s
            rotation: -18
            z: 10

            property real t: 0
            NumberAnimation on t {
                from: 0
                to: Math.PI * 2
                duration: 18000
                loops: Animation.Infinite
                running: true
            }

            Shape {
                anchors.fill: parent
                opacity: 0.25
                antialiasing: true
                ShapePath {
                    strokeWidth: 1.2
                    strokeColor: root.orbitClr
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin
                    PathAngleArc {
                        centerX: 160 * s
                        centerY: 50 * s
                        radiusX: 160 * s
                        radiusY: 50 * s
                        startAngle: 0
                        sweepAngle: 360
                    }
                }
            }

            Rectangle {
                id: traveler
                width: 8 * s
                height: 8 * s
                radius: 4 * s
                color: root.orbitClr
                opacity: 0.6
                antialiasing: true
                x: (160 * s) + (160 * s * Math.cos(orbitalSpace.t)) - (width / 2)
                y: (50 * s) + (50 * s * Math.sin(orbitalSpace.t)) - (height / 2)
            }
        }

        Row {
            id: timeLabels
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 15 * s
            z: 50

            Text {
                id: hhLab
                text: Qt.formatTime(new Date(), "HH")
                font.family: root._fontFamily
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.fg
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
            Text {
                id: mmLab
                text: Qt.formatTime(new Date(), "mm")
                font.family: root._fontFamily
                font.pixelSize: 100 * s
                font.letterSpacing: 4 * s
                color: root.fg
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
            }
        }

        Column {
            anchors.right: parent.right
            anchors.top: timeLabels.bottom
            anchors.topMargin: 0
            spacing: 5 * s
            z: 100
            Text {
                text: Qt.formatDate(new Date(), "dddd").toUpperCase()
                font.family: root._fontFamily
                font.pixelSize: 16 * s
                font.letterSpacing: 8 * s
                color: root.gold
                opacity: 0.8
                anchors.right: parent.right
            }
            Row {
                anchors.right: parent.right
                spacing: 12 * s
                Rectangle {
                    width: 40 * s
                    height: 1
                    color: root.gold
                    opacity: 0.3
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: Qt.formatDate(new Date(), "MMM dd yyyy").toUpperCase()
                    font.family: root._fontFamily
                    font.pixelSize: 12 * s
                    font.letterSpacing: 4 * s
                    color: root.fg
                    opacity: 0.6
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                hhLab.text = Qt.formatTime(new Date(), "HH");
                mmLab.text = Qt.formatTime(new Date(), "mm");
            }
        }
    }

    // Identity
    Column {
        id: identityStack
        anchors.right: parent.right
        anchors.rightMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 12 * s
        width: 450 * s

        SequentialAnimation {
            id: typingAnim
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.0
                to: 1.01
                duration: 40
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: identityStack
                property: "scale"
                from: 1.01
                to: 1.0
                duration: 100
            }
        }

        Item {
            width: parent.width
            height: uLabel.height
            z: 2000
            Text {
                id: uLabel
                text: (userHelper.currentItem && userHelper.currentItem.uName ? userHelper.currentItem.uName : "UNKNOWN").toUpperCase()
                font.family: root._fontFamily
                font.pixelSize: 48 * s
                font.letterSpacing: 4 * s
                color: (root.userMenuOpen || uMa.containsMouse) ? root.gold : root.fg
                anchors.right: parent.right
                scale: uMa.containsMouse ? 1.05 : 1.0
                transformOrigin: Item.Right
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 12
                }
                MouseArea {
                    id: uMa
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.userMenuOpen = !root.userMenuOpen;
                    }
                }
            }
            Item {
                id: uMenu
                anchors.bottom: uLabel.top
                anchors.bottomMargin: 20 * s
                anchors.right: parent.right
                width: 320 * s
                height: root.userMenuOpen ? (40 * s * (typeof userModel !== "undefined" ? userModel.rowCount() : 0)) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.gold
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.rightMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: typeof userModel !== "undefined" ? userModel : null
                        delegate: Item {
                            width: 300 * s
                            height: 32 * s
                            property bool itemHover: uItemMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 12 * s
                                color: root.gold
                                anchors.right: parent.right
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: (model.realName || model.name).toUpperCase()
                                font.family: root._fontFamily
                                font.pixelSize: 14 * s
                                font.letterSpacing: 2 * s
                                color: root.fg
                                opacity: (root.userIndex === index || uItemMa.containsMouse) ? 1.0 : 0.4
                                anchors.right: parent.right
                                anchors.rightMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                id: uItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.userIndex = index;
                                    root.userMenuOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }
        Row {
            anchors.right: parent.right
            spacing: 12 * s
            Rectangle {
                width: 60 * s
                height: 1
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "✦"
                font.pixelSize: 10 * s
                color: root.gold
                opacity: 0.4
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle {
                width: 60 * s
                height: 1
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Item {
            id: inputWrapper
            width: parent.width
            height: 48 * s

            TextInput {
                id: passInput
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignRight
                echoMode: TextInput.Password
                passwordCharacter: "✦"
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhSensitiveData | Qt.ImhNoAutoUppercase
                font.family: root._fontFamily
                font.pixelSize: 22 * s
                font.letterSpacing: 10 * s
                color: root.fg
                focus: true
                readOnly: root.authPending
                property bool wasClicked: false
                cursorVisible: false
                Binding {
                    target: passInput
                    property: "text"
                    value: root.passwordText
                    when: root._hasSharedLockState
                }
                cursorDelegate: Item {
                    width: 0
                    height: 0
                }
                selectionColor: root.gold
                rightPadding: root.passwordText.length > 0 ? 50 * s : 0
                onTextEdited: {
                    if (!root.authPending)
                        root.setPasswordText(passInput.text);
                }
                Behavior on rightPadding {
                    NumberAnimation {
                        duration: 350
                        easing.type: Easing.OutCubic
                    }
                }
                onTextChanged: typingAnim.restart()
                onAccepted: doLogin()

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: root.authPending ? 44 * s : 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.authPending ? "V E R I F Y I N G" : "W A I T I N G   F O R   P A S S W O R D"
                    font.family: root._fontFamily
                    font.pixelSize: 12 * s
                    font.letterSpacing: 3 * s
                    color: root.gold
                    opacity: root.passwordText.length === 0 ? (root.authPending ? 0.72 : 0.4) : 0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 400
                            easing.type: Easing.InOutSine
                        }
                    }
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 3
                    }
                }

                Rectangle {
                    id: customCursor
                    width: 2 * s
                    height: 24 * s
                    color: root.gold
                    anchors.verticalCenter: parent.verticalCenter
                    x: passInput.cursorRectangle.x
                    visible: passInput.focus && (passInput.text.length > 0 || passInput.wasClicked)
                    SequentialAnimation {
                        loops: Animation.Infinite
                        running: customCursor.visible
                        NumberAnimation {
                            target: customCursor
                            property: "opacity"
                            from: 1
                            to: 0.05
                            duration: 450
                        }
                        NumberAnimation {
                            target: customCursor
                            property: "opacity"
                            from: 0.05
                            to: 1
                            duration: 450
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        passInput.forceActiveFocus();
                        passInput.wasClicked = true;
                    }
                }
            }

            Item {
                id: loginBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 32 * s
                height: 32 * s
                opacity: (root.passwordText.length > 0 || root.authPending) ? 0.8 : 0
                scale: (root.passwordText.length > 0 || root.authPending) ? 1.0 : 0.8
                Behavior on opacity {
                    NumberAnimation {
                        duration: 350
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutBack
                    }
                }
                Text {
                    text: "✦"
                    font.pixelSize: 14 * s
                    color: arrowMa.containsMouse ? root.gold : root.fg
                    anchors.centerIn: parent
                    layer.enabled: true
                    layer.effect: DropShadow {
                        color: "#aa000000"
                        radius: 4
                    }
                }
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: root.gold
                    border.width: 1
                    opacity: 0.2
                    rotation: 45
                }
                MouseArea {
                    id: arrowMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: doLogin()
                }
            }
        }
        Text {
            id: errText
            width: parent.width
            horizontalAlignment: Text.AlignRight
            height: 15 * s
            verticalAlignment: Text.AlignTop
            color: root.authPending ? root.gold : "#ff4444"
            font.family: root._fontFamily
            font.pixelSize: 12 * s
            font.letterSpacing: 2 * s
            text: root.errorMessage
            opacity: root.errorMessage.length > 0 ? 1 : 0
        }
    }

    // Logistics
    Column {
        anchors.left: parent.left
        anchors.leftMargin: 100 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * s
        spacing: 15 * s
        z: 1000

        Item {
            width: sLabel.width
            height: sLabel.height
            visible: !root.isQuickshell
            Text {
                id: sLabel
                text: (sessionHelper.currentItem && sessionHelper.currentItem.sName ? sessionHelper.currentItem.sName : "WAYLAND").toUpperCase()
                font.family: root._fontFamily
                font.pixelSize: 18 * s
                font.letterSpacing: (sMa.containsMouse || root.sessionMenuOpen) ? 8 * s : 6 * s
                color: (root.sessionMenuOpen || sMa.containsMouse) ? root.gold : root.fg
                opacity: 0.8
                Behavior on color {
                    ColorAnimation {
                        duration: 250
                    }
                }
                Behavior on font.letterSpacing {
                    NumberAnimation {
                        duration: 450
                        easing.type: Easing.OutQuart
                    }
                }
                layer.enabled: true
                layer.effect: DropShadow {
                    color: "#aa000000"
                    radius: 4
                }
                MouseArea {
                    id: sMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.sessionMenuOpen = !root.sessionMenuOpen;
                    }
                }
            }
            Item {
                id: sMenu
                anchors.bottom: parent.top
                anchors.bottomMargin: 20 * s
                anchors.left: parent.left
                width: 320 * s
                height: root.sessionMenuOpen ? (40 * s * (typeof sessionModel !== "undefined" ? sessionModel.rowCount() : 0)) + 20 : 0
                clip: true
                Behavior on height {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: root.gold
                    opacity: 0.4
                }
                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 15 * s
                    anchors.topMargin: 10 * s
                    spacing: 8 * s
                    Repeater {
                        model: typeof sessionModel !== "undefined" ? sessionModel : null
                        delegate: Item {
                            width: 250 * s
                            height: 32 * s
                            property bool itemHover: mMa.containsMouse
                            Text {
                                text: "✦"
                                font.pixelSize: 12 * s
                                color: root.gold
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                text: model.name.toUpperCase()
                                font.family: root._fontFamily
                                font.pixelSize: 14 * s
                                font.letterSpacing: 2 * s
                                color: root.fg
                                opacity: (root.sessionIndex === index || mMa.containsMouse) ? 1.0 : 0.4
                                anchors.left: parent.left
                                anchors.leftMargin: 25 * s
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            MouseArea {
                                id: mMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    root.sessionIndex = index;
                                    root.sessionMenuOpen = false;
                                }
                            }
                        }
                    }
                }
            }
        }

        Row {
            spacing: 25 * s
            visible: root._powerRowVisible
            Text {
                text: "REBOOT"
                font.family: root._fontFamily
                font.pixelSize: 12 * s
                font.letterSpacing: 2 * s
                color: root.fg
                opacity: rMa.containsMouse ? 1.0 : 0.4
                scale: rMa.containsMouse ? 1.05 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    ColorAnimation {
                        duration: 250
                    }
                }
                MouseArea {
                    id: rMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (typeof sddm !== "undefined")
                            sddm.reboot();
                    }
                }
            }
            Rectangle {
                width: 1
                height: 10 * s
                color: root.gold
                opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "SHUTDOWN"
                font.family: root._fontFamily
                font.pixelSize: 12 * s
                font.letterSpacing: 2 * s
                color: root.fg
                opacity: pMa.containsMouse ? 1.0 : 0.4
                scale: pMa.containsMouse ? 1.05 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on opacity {
                    ColorAnimation {
                        duration: 250
                    }
                }
                MouseArea {
                    id: pMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (typeof sddm !== "undefined")
                            sddm.powerOff();
                    }
                }
            }
        }
    }

    // Action
    function doLogin() {
        if (root.authPending) {
            refocusPasswordInput();
            return;
        }
        if (root.passwordText.length === 0) {
            passInput.wasClicked = true;
            refocusPasswordInput();
            return;
        }
        var n = "";
        if (userHelper.currentItem && userHelper.currentItem.uName !== "") {
            n = userHelper.currentItem.uLogin;
        } else if (typeof userModel !== "undefined") {
            n = userModel.lastUser;
        }
        if (typeof sddm !== "undefined") {
            var password = root.passwordText;
            root.setAuthPending(true);
            root.setPasswordText("");
            passInput.wasClicked = true;
            refocusPasswordInput();
            sddm.login(n, password, root.sessionIndex);
        }
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        function onLoginSucceeded() {
            root.setAuthPending(false);
            root.clearError();
        }
        function onLoginFailed() {
            root.setAuthPending(false);
            root.setErrorMessage("ACCESS DENIED");
            root.setPasswordText("");
            passInput.wasClicked = true;
            refocusPasswordInput();
            focusRepairTimer.kick();
        }
    }

    Timer {
        interval: 300
        running: true
        onTriggered: refocusPasswordInput()
    }
    Timer {
        id: focusRepairTimer
        property int remaining: 0
        interval: 40
        repeat: true
        function kick() {
            remaining = 8;
            restart();
        }
        onTriggered: {
            refocusPasswordInput();
            remaining -= 1;
            if (remaining <= 0)
                stop();
        }
    }
    Component.onCompleted: keyboard.numLock = true
}
