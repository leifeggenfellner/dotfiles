pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/hypr"

// ── WorkspaceCarousel ─────────────────────────────────────────
// The workspace carousel (D-067): card plates on a drum under the
// workspace strip. The front card is large; two neighbours on each
// side turn away on the drum's axis, smaller and dimmer; the rest are
// hidden. It draws ShellState's carousel fields; CarouselController
// decides them.
//
// The drum turns on Motion.instrumentSettle. With motion reduced or
// the ambient governor off it does not turn: the cards take their new
// places at once and the drum cross-fades.
//
// With `carousel.capture` set, each visible card shows its workspace
// in miniature from single-frame window captures (D-068). Geometry is
// re-read when the carousel opens and when windows come or go; a card
// that leaves view drops its captures, and closing drops them all.
//
// Click a card to switch to it; scroll or ←/→ to turn; Enter switches
// to the front card; Esc closes. Only a deliberate open (reason
// "keys") takes the keyboard; opened by the pointer it gets focus when
// clicked, and a workspace switch never takes it.

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

    readonly property int cardWidth: 320
    readonly property int cardHeight: 200
    // Drum radius and the angle between neighbouring cards.
    readonly property real radius: 340
    readonly property real step: 35
    readonly property int reach: 2

    function turnTo(index) {
        const i = Math.max(0, Math.min(items.length - 1, index));
        ShellState.showCarousel(carousel.screen.name, items[i].id, ShellState.carouselReason || "scroll");
    }

    function choose(index) {
        const id = items[index].id;
        ShellState.showCarousel(carousel.screen.name, id, "chosen");
        HyprState.switchWorkspace(id);
    }

    visible: open || drum.opacity > 0.01

    Component.onCompleted: if (captures)
        HyprState.refreshWindows()

    Connections {
        target: carousel.captures ? HyprState : null
        function onWorkspaceWindowsChanged() {
            HyprState.refreshWindows();
        }
    }

    WlrLayershell.namespace: "rice-carousel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: {
        if (!open || ShellState.carouselReason === "switch")
            return WlrKeyboardFocus.None;
        return ShellState.carouselReason === "keys" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand;
    }

    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.metrics.bar.height + Theme.metrics.space.md + cardHeight + Theme.metrics.space.lg * 2
    color: "transparent"
    mask: Region {
        item: drum
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: ShellState.hideCarousel()
        Keys.onLeftPressed: carousel.turnTo(carousel.frontIndex - 1)
        Keys.onRightPressed: carousel.turnTo(carousel.frontIndex + 1)
        Keys.onReturnPressed: carousel.choose(carousel.frontIndex)

        Item {
            id: drum

            // The card the drum faces, as a fractional index while it turns.
            property real position: carousel.frontIndex
            readonly property real anchorX: ShellState.carouselAnchor >= 0 ? ShellState.carouselAnchor : carousel.width / 2

            width: 2 * carousel.radius * Math.sin(carousel.reach * carousel.step * Math.PI / 180) + carousel.cardWidth
            height: carousel.cardHeight + Theme.metrics.space.lg * 2
            // The front card stays under the strip and on screen; the
            // neighbours may run off the edge.
            x: Math.max(carousel.cardWidth / 2 + Theme.metrics.space.md, Math.min(carousel.width - carousel.cardWidth / 2 - Theme.metrics.space.md, anchorX)) - width / 2
            y: Theme.metrics.bar.height + Theme.metrics.space.md + (carousel.open ? 0 : -Theme.metrics.space.md)
            opacity: carousel.open ? 1 : 0

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
            Behavior on y {
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

            HoverHandler {
                onHoveredChanged: ShellState.carouselDrumHovered = hovered
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

                        width: carousel.cardWidth
                        height: carousel.cardHeight
                        x: drum.width / 2 + carousel.radius * Math.sin(angle * Math.PI / 180) - width / 2
                        y: Theme.metrics.space.lg
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
