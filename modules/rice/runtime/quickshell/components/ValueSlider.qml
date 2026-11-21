import QtQuick
import "../core"

// ── ValueSlider ───────────────────────────────────────────────
// A level [0..1] with its icon and percentage. Drag, scroll or use
// ←/→ (5 %) to ask for a new value through `moved(v)`; the fill shows
// `value` as the service reports it. The icon asks `iconClicked()`
// (mute); with `hasPage`, a chevron asks `opened()`. Optional:
// `image` (a URL, e.g. an app icon) in place of the icon, `label`
// above the track, and `level` [0..1] as a live meter under it
// (negative hides it).

FocusScope {
    id: root

    property string icon: ""
    property real value: 0
    property bool muted: false
    property bool hasPage: false
    property real step: 0.05
    property string image: ""
    property string label: ""
    property real level: -1

    signal moved(real v)
    signal iconClicked
    signal opened

    implicitHeight: label.length > 0 ? 42 : 32
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

    Item {
        id: glyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.typography.sizes.icon
        height: width

        Icon {
            visible: root.image.length === 0
            anchors.centerIn: parent
            name: root.icon.length > 0 ? root.icon : "unknown"
            size: Theme.typography.sizes.icon
            color: root.muted ? Theme.colors.fg.subtle : (iconMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted)
        }
        Image {
            visible: root.image.length > 0
            anchors.fill: parent
            source: root.image
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            opacity: root.muted ? 0.4 : 1
            smooth: true
        }

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

    Text {
        visible: root.label.length > 0
        anchors.left: track.left
        anchors.right: track.right
        anchors.bottom: track.top
        anchors.bottomMargin: -3
        text: root.label
        elide: Text.ElideRight
        color: root.muted ? Theme.colors.fg.subtle : Theme.colors.fg.muted
        font.family: Theme.typography.families.sans
        font.pointSize: Theme.typography.sizes.small
    }

    Item {
        id: track
        anchors.left: glyph.right
        anchors.leftMargin: Theme.metrics.space.md
        anchors.right: readout.left
        anchors.rightMargin: Theme.metrics.space.sm
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.label.length > 0 ? 7 : 0
        height: 20

        // The live level, under the fill.
        Rectangle {
            visible: root.level >= 0
            anchors.top: parent.verticalCenter
            anchors.topMargin: 5
            width: parent.width * Math.max(0, Math.min(1, root.level))
            height: 2
            radius: 1
            color: root.muted ? Theme.colors.bg.surface2 : Theme.colors.fg.subtle
        }

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
