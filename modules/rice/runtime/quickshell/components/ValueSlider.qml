import QtQuick
import "../core"

// ── ValueSlider ───────────────────────────────────────────────
// A level [0..1] with its icon and percentage. Drag, scroll or use
// ←/→ (5 %) to ask for a new value through `moved(v)`; the fill shows
// `value` as the service reports it. The icon asks `iconClicked()`
// (mute); with `hasPage`, a chevron asks `opened()`.

FocusScope {
    id: root

    property string icon: ""
    property real value: 0
    property bool muted: false
    property bool hasPage: false
    property real step: 0.05

    signal moved(real v)
    signal iconClicked
    signal opened

    implicitHeight: 32
    activeFocusOnTab: true

    function nudge(delta) {
        root.moved(Math.max(0, Math.min(1, root.value + delta)));
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: Theme.metrics.radius.small
        color: "transparent"
        border.width: root.activeFocus ? 2 : 0
        border.color: Theme.colors.fg.primary
    }

    Icon {
        id: glyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: Theme.typography.sizes.icon
        color: root.muted ? Theme.colors.fg.subtle : (iconMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted)

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            anchors.margins: -Theme.metrics.space.xs
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Item {
        id: chevron
        visible: root.hasPage
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.hasPage ? 20 : 0
        height: parent.height

        Icon {
            anchors.centerIn: parent
            name: "chevron-right"
            size: Theme.typography.sizes.body
            color: chevronMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle
        }
        MouseArea {
            id: chevronMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened()
        }
    }

    Text {
        id: readout
        anchors.right: chevron.left
        anchors.rightMargin: Theme.metrics.space.xs
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        color: root.muted ? Theme.colors.fg.subtle : Theme.colors.fg.muted
        font.family: Theme.typography.families.mono
        font.pointSize: Theme.typography.sizes.small
    }

    Item {
        id: track
        anchors.left: glyph.right
        anchors.leftMargin: Theme.metrics.space.md
        anchors.right: readout.left
        anchors.rightMargin: Theme.metrics.space.sm
        anchors.verticalCenter: parent.verticalCenter
        height: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 6
            radius: 3
            color: Theme.colors.bg.surface1

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.value))
                height: parent.height
                radius: parent.radius
                color: root.muted ? Theme.colors.fg.subtle : Theme.colors.accent.primary
            }
        }

        Rectangle {
            x: (parent.width - width) * Math.max(0, Math.min(1, root.value))
            anchors.verticalCenter: parent.verticalCenter
            width: drag.pressed || drag.containsMouse || root.activeFocus ? 14 : 10
            height: width
            radius: width / 2
            color: root.muted ? Theme.colors.fg.subtle : Theme.colors.accent.primary
            border.width: 2
            border.color: Theme.colors.bg.mantle

            Behavior on width {
                MotionAnim {
                    spec: Motion.stateChange
                }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function at(x) {
                return Math.max(0, Math.min(1, (x - 6) / track.width));
            }
            onPressed: mouse => {
                root.forceActiveFocus();
                root.moved(at(mouse.x));
            }
            onPositionChanged: mouse => {
                if (pressed)
                    root.moved(at(mouse.x));
            }
            onWheel: wheel => root.nudge(wheel.angleDelta.y > 0 ? root.step : -root.step)
        }
    }

    Keys.onLeftPressed: root.nudge(-root.step)
    Keys.onRightPressed: root.nudge(root.step)
    Keys.onSpacePressed: root.iconClicked()
    Keys.onReturnPressed: event => {
        if (root.hasPage)
            root.opened();
        else
            event.accepted = false;
    }
}
