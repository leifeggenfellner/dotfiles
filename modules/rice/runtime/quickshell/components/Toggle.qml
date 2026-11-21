import QtQuick
import "../core"

// ── Toggle ────────────────────────────────────────────────────
// An on/off switch. It shows `checked` as the service reports it and
// asks for a change through `toggled()`; `busy` dims it meanwhile.

Rectangle {
    id: root

    property bool checked: false
    property bool busy: false
    signal toggled

    implicitWidth: 34
    implicitHeight: 18
    radius: height / 2
    color: checked ? Theme.colors.accent.primary : Theme.colors.bg.surface1
    border.width: activeFocus ? 2 : 0
    border.color: Theme.colors.fg.primary
    opacity: busy ? 0.5 : 1
    activeFocusOnTab: true

    Behavior on color {
        ColorAnimation {
            duration: Motion.stateChange.duration
        }
    }

    Rectangle {
        width: parent.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? parent.width - width - 2 : 2
        color: root.checked ? Theme.colors.bg.sunken : Theme.colors.fg.muted

        Behavior on x {
            MotionAnim {
                spec: Motion.stateChange
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Keys.onSpacePressed: root.toggled()
    Keys.onReturnPressed: root.toggled()
    Keys.onEnterPressed: root.toggled()
}
