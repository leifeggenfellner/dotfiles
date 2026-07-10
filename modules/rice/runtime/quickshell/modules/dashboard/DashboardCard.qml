import QtQuick
import "../../core"

// Uniform dashboard chrome for v2. Widgets provide content only; the card owns
// title treatment, surface states, hover/focus affordances, and retry UI.
Item {
    id: root

    default property alias contentData: bodyContent.data
    property alias actionSlot: actionHost.data

    property string title: ""
    property string subtitle: ""
    property bool busy: false
    property bool error: false
    property bool empty: false
    property string errorText: "The mirror is clouded."
    property string emptyText: "No omen answers."
    property string busyGlyph: "☉"
    property var retryAction: null
    property bool focusRing: false

    readonly property bool _stateVisible: busy || error || empty
    readonly property bool _headerVisible: title.length > 0 || subtitle.length > 0 || actionHost.children.length > 0
    readonly property int _pad: Theme.metrics.space.lg
    readonly property int _headerHeight: _headerVisible ? Math.max(titleStack.implicitHeight, actionHost.implicitHeight) : 0
    readonly property int _contentHeight: _stateVisible ? statePane.implicitHeight : Math.max(bodyContent.childrenRect.height, Theme.metrics.space.lg * 2)

    implicitHeight: _pad * 2 + _headerHeight + (_headerVisible ? Theme.metrics.space.md : 0) + _contentHeight
    height: implicitHeight

    Rectangle {
        id: frame

        property real lift: hoverArea.containsMouse ? -2 : 0

        anchors.fill: parent
        radius: Theme.metrics.radius.medium
        color: Theme.colors.bg.elevated
        border.width: root.focusRing ? 2 : 1
        border.color: root.focusRing || hoverArea.containsMouse ? Theme.colors.accent.primary : Theme.colors.bg.surface1
        transform: Translate {
            y: frame.lift
        }

        Behavior on lift {
            MotionAnim {
                spec: Motion.stateChange
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, parent.radius - 1)
            color: Theme.colors.bg.mantle
            opacity: 0.18
        }

        Column {
            anchors.fill: parent
            anchors.margins: root._pad
            spacing: root._headerVisible ? Theme.metrics.space.md : 0

            Item {
                width: parent.width
                height: root._headerHeight
                visible: root._headerVisible

                Column {
                    id: titleStack

                    width: parent.width - actionHost.width - (actionHost.width > 0 ? Theme.metrics.space.md : 0)
                    spacing: Theme.metrics.space.xs

                    Text {
                        width: parent.width
                        text: root.title.toUpperCase()
                        visible: root.title.length > 0
                        color: Theme.colors.fg.primary
                        elide: Text.ElideRight
                        font.family: Theme.typography.families.display
                        font.pointSize: Theme.typography.sizes.small + 1
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0
                    }

                    Text {
                        width: parent.width
                        text: root.subtitle
                        visible: root.subtitle.length > 0
                        color: Theme.colors.fg.subtle
                        elide: Text.ElideRight
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.small
                        font.letterSpacing: 0
                    }
                }

                Item {
                    id: actionHost

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                }
            }

            Item {
                id: contentHost

                width: parent.width
                height: root._contentHeight

                Item {
                    id: bodyContent

                    width: parent.width
                    height: childrenRect.height
                    visible: !root._stateVisible
                }

                Item {
                    id: statePane

                    width: parent.width
                    visible: root._stateVisible
                    implicitHeight: stateColumn.implicitHeight

                    Column {
                        id: stateColumn

                        width: parent.width
                        spacing: Theme.metrics.space.sm

                        Text {
                            id: glyph

                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.busy ? root.busyGlyph : (root.error ? "☍" : "○")
                            color: root.error ? Theme.colors.state.warn : Theme.colors.accent.secondary
                            opacity: root.busy ? 0.58 : 0.72
                            font.family: Theme.typography.families.display
                            font.pointSize: Theme.typography.sizes.heading + 10

                            SequentialAnimation on opacity {
                                running: root.busy && Motion.enabled
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.22
                                    duration: Math.max(900, Theme.motion.durations.slow)
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 0.62
                                    duration: Math.max(900, Theme.motion.durations.slow)
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.error ? root.errorText : (root.empty ? root.emptyText : "Consulting the glass...")
                            color: Theme.colors.fg.subtle
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.body
                            font.letterSpacing: 0
                        }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: retryLabel.implicitWidth + Theme.metrics.space.md * 2
                            height: retryLabel.implicitHeight + Theme.metrics.space.sm * 2
                            visible: root.error && root.retryAction !== null
                            radius: Theme.metrics.radius.small
                            color: retryMouse.containsMouse ? Theme.colors.bg.surface2 : Theme.colors.bg.surface1
                            border.width: 1
                            border.color: retryMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.bg.surface2

                            Text {
                                id: retryLabel
                                anchors.centerIn: parent
                                text: "Retry"
                                color: Theme.colors.accent.primary
                                font.family: Theme.typography.families.mono
                                font.pointSize: Theme.typography.sizes.small
                            }

                            MouseArea {
                                id: retryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.retryAction()
                            }
                        }
                    }
                }
            }
        }
    }
}
