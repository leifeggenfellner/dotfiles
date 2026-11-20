pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/hypr"

// ── WorkspaceCarousel ─────────────────────────────────────────
// The full-screen workspace carousel (D-069): card plates on a drum
// over a dimmed screen. The front card is about half the screen wide;
// two neighbours on each side turn away on the drum's axis, smaller
// and dimmer; the rest are hidden. It draws ShellState's carousel
// fields; CarouselController writes them.
//
// With `carousel.capture` set, each visible card shows its workspace
// in miniature from single-frame window captures (D-068). Geometry is
// re-read when the carousel opens and when windows come or go; a card
// that leaves view drops its captures, and closing drops them all.
//
// The drum turns on Motion.instrumentSettle. With motion reduced or
// the ambient governor off it does not turn: the cards take their new
// places at once and cross-fade.
//
// ←/→, Tab or the wheel turn it; a digit faces that workspace; Enter
// or a click on a card goes there; Esc or a click outside closes.

PanelWindow {
    id: carousel

    required property var modelData
    screen: modelData

    readonly property var settings: Theme.widgetConfig("workspaces").settings ?? ({})
    readonly property var style: settings.carousel ?? ({})
    readonly property var items: settings.items ?? []
    readonly property bool open: ShellState.carouselScreen === carousel.screen.name
    readonly property int frontIndex: Math.max(0, items.findIndex(i => i.id === ShellState.carouselWorkspace))
    readonly property bool turning: Motion.enabled && ShellState.ambientActive
    readonly property bool captures: (style.capture ?? null) !== null

    // The front card fills about half the screen; the drum's radius
    // and the card chrome scale with it.
    readonly property real aspect: width > 0 && height > 0 ? width / height : 16 / 10
    readonly property real cardWidth: Math.min(width * 0.5, height * 0.58 * aspect)
    readonly property real unit: Math.max(1, Math.min(2.2, cardWidth / 320 * 0.6))
    readonly property real radius: cardWidth * 1.05
    readonly property real step: 35
    readonly property int reach: 2

    function turnTo(index) {
        const i = Math.max(0, Math.min(items.length - 1, index));
        ShellState.showCarousel(carousel.screen.name, items[i].id);
    }

    function choose(index) {
        HyprState.switchWorkspace(items[index].id);
        ShellState.hideCarousel();
    }

    visible: open || backdrop.opacity > 0.01

    WlrLayershell.namespace: "rice-carousel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    Component.onCompleted: if (captures)
        HyprState.refreshWindows()

    Connections {
        target: carousel.captures ? HyprState : null
        function onWorkspaceWindowsChanged() {
            HyprState.refreshWindows();
        }
    }

    Rectangle {
        id: backdrop

        anchors.fill: parent
        color: Theme.colors.bg.base
        opacity: carousel.open ? 0.88 : 0

        Behavior on opacity {
            MotionAnim {
                spec: carousel.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.hideCarousel()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ShellState.hideCarousel()
        Keys.onLeftPressed: carousel.turnTo(carousel.frontIndex - 1)
        Keys.onRightPressed: carousel.turnTo(carousel.frontIndex + 1)
        Keys.onTabPressed: carousel.turnTo(carousel.frontIndex + 1)
        Keys.onBacktabPressed: carousel.turnTo(carousel.frontIndex - 1)
        Keys.onReturnPressed: carousel.choose(carousel.frontIndex)
        Keys.onEnterPressed: carousel.choose(carousel.frontIndex)
        Keys.onPressed: event => {
            const at = carousel.items.findIndex(i => String(i.id) === event.text);
            if (at >= 0) {
                carousel.turnTo(at);
                event.accepted = true;
            }
        }

        Item {
            id: drum

            // The card the drum faces, as a fractional index while it turns.
            property real position: carousel.frontIndex

            anchors.centerIn: parent
            width: parent.width
            height: repeater.count > 0 && repeater.itemAt(0) ? repeater.itemAt(0).implicitHeight : 0
            opacity: carousel.open ? 1 : 0
            scale: carousel.open ? 1 : 0.96

            Behavior on position {
                enabled: carousel.turning
                MotionAnim {
                    spec: Motion.instrumentSettle
                }
            }
            Behavior on opacity {
                MotionAnim {
                    spec: carousel.open ? Motion.panelOpen : Motion.panelClose
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: carousel.open ? Motion.panelOpen : Motion.panelClose
                }
            }

            // Without the turn, the cards cross-fade to their new places.
            SequentialAnimation {
                id: crossFade
                PropertyAction {
                    target: cards
                    property: "opacity"
                    value: 0.35
                }
                MotionAnim {
                    target: cards
                    property: "opacity"
                    to: 1
                    spec: Motion.stateChange
                }
            }
            Connections {
                target: carousel
                function onFrontIndexChanged() {
                    if (!carousel.turning && carousel.open)
                        crossFade.restart();
                }
            }

            WheelHandler {
                property real pending: 0

                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    pending += event.angleDelta.y || event.angleDelta.x;
                    const steps = Math.trunc(pending / 120);
                    if (steps !== 0) {
                        pending -= steps * 120;
                        carousel.turnTo(carousel.frontIndex - steps);
                    }
                }
            }

            Item {
                id: cards
                anchors.fill: parent

                Repeater {
                    id: repeater

                    model: carousel.items

                    delegate: CarouselCard {
                        id: card

                        required property var modelData
                        required property int index

                        readonly property real offset: index - drum.position
                        readonly property real distance: Math.abs(offset)
                        readonly property real angle: Math.max(-90, Math.min(90, offset * carousel.step))

                        entry: modelData
                        windows: HyprState.workspaceWindows[modelData.id] ?? 0
                        apps: windows > 0 ? HyprState.workspaceApps(modelData.id) : []
                        layout: carousel.captures && visible && windows > 0 ? HyprState.workspaceLayout(modelData.id) : null
                        style: carousel.style
                        front: distance < 0.5
                        unit: carousel.unit
                        aspect: carousel.aspect

                        width: carousel.cardWidth
                        height: implicitHeight
                        x: drum.width / 2 + carousel.radius * Math.sin(angle * Math.PI / 180) - width / 2
                        z: 10 - distance
                        visible: distance < carousel.reach + 0.5
                        scale: 1 - 0.16 * Math.min(distance, carousel.reach)
                        transform: Rotation {
                            origin.x: card.width / 2
                            origin.y: card.height / 2
                            axis {
                                x: 0
                                y: 1
                                z: 0
                            }
                            angle: card.angle
                        }

                        // Dims with distance from the front.
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.metrics.radius.medium
                            color: Theme.colors.bg.base
                            opacity: 0.3 * Math.min(card.distance, carousel.reach)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: carousel.choose(card.index)
                        }
                    }
                }
            }
        }
    }
}
