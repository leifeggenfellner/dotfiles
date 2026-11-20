import QtQuick
import Quickshell.Io
import "../../core"
import "../../services/hypr"

// ── CarouselController ────────────────────────────────────────
// When the workspace carousel (D-067) opens, turns and goes away.
// The surface only draws ShellState's carousel fields; this decides
// them. Off unless the theme sets widgets.workspaces.settings.carousel.
//
//   switch  a workspace switch on a screen shows it turned to the new
//           card; it leaves after `dwell` without the pointer on it
//   hover   resting on the strip for `hoverDelay` shows it; it follows
//           the bezel under the pointer and leaves `grace` after the
//           pointer is on neither the strip nor the drum
//   scroll  set by the strip itself; dismissed like hover
//   keys    opened on purpose (IPC `open`, for a keybind): it stays
//           until Esc, Enter or a click, and takes the keyboard
//   chosen  a card was clicked: it closes, and the switch that follows
//           does not reopen it
//
// External control: quickshell -p <runtime> ipc call carousel <fn>

Item {
    id: controller

    readonly property var settings: Theme.widgetConfig("workspaces").settings ?? ({})
    readonly property bool enabled: (settings.carousel ?? null) !== null
    readonly property var items: settings.items ?? []
    readonly property bool open: ShellState.carouselScreen.length > 0

    // Proposed in the brief and to be revisited after living with it.
    readonly property int dwell: 900
    readonly property int hoverDelay: 350
    readonly property int grace: 300
    property real swallowUntil: 0

    readonly property var pointer: ShellState.carouselPointer
    readonly property bool pointerIn: open && ((pointer !== null && pointer.screen === ShellState.carouselScreen) || ShellState.carouselDrumHovered)

    function has(workspaceId) {
        return items.some(i => i.id === workspaceId);
    }

    function show(screenName, workspaceId, reason) {
        if (enabled && has(workspaceId))
            ShellState.showCarousel(screenName, workspaceId, reason);
    }

    function openFocused() {
        const screenName = HyprState.focusedScreenName || ShellState.carouselScreen;
        show(screenName, HyprState.activeWorkspaceForScreen(screenName), "keys");
    }

    function turn(steps) {
        if (!open)
            return;
        const at = items.findIndex(i => i.id === ShellState.carouselWorkspace);
        const next = Math.max(0, Math.min(items.length - 1, at + steps));
        ShellState.showCarousel(ShellState.carouselScreen, items[next].id, ShellState.carouselReason);
    }

    function settle() {
        if (!open || pointerIn || ShellState.carouselReason === "keys") {
            dismiss.stop();
            return;
        }
        dismiss.interval = ShellState.carouselReason === "switch" ? dwell : grace;
        dismiss.restart();
    }

    onEnabledChanged: if (!enabled)
        ShellState.hideCarousel()
    onPointerInChanged: settle()

    // The bezel under the pointer: wait before opening, then follow.
    onPointerChanged: {
        if (!enabled || pointer === null || pointer.workspace <= 0) {
            hoverOpen.stop();
            return;
        }
        if (open && pointer.screen === ShellState.carouselScreen) {
            if (pointer.workspace !== ShellState.carouselWorkspace)
                show(pointer.screen, pointer.workspace, "hover");
        } else {
            hoverOpen.restart();
        }
    }

    Timer {
        id: hoverOpen
        interval: controller.hoverDelay
        onTriggered: {
            const p = controller.pointer;
            if (p !== null && p.workspace > 0)
                controller.show(p.screen, p.workspace, "hover");
        }
    }

    Timer {
        id: dismiss
        onTriggered: if (!controller.pointerIn)
            ShellState.hideCarousel()
    }

    Connections {
        target: ShellState
        function onCarouselSerialChanged() {
            if (ShellState.carouselReason === "chosen") {
                controller.swallowUntil = Date.now() + 1000;
                ShellState.hideCarousel();
                return;
            }
            controller.settle();
        }
    }

    Connections {
        target: controller.enabled ? HyprState : null
        function onWorkspaceSwitched(screenName, workspaceId) {
            if (Date.now() < controller.swallowUntil) {
                controller.swallowUntil = 0;
                return;
            }
            const keep = controller.open && ShellState.carouselScreen === screenName && ShellState.carouselReason !== "switch";
            if (keep && ShellState.carouselWorkspace === workspaceId)
                return;
            controller.show(screenName, workspaceId, keep ? ShellState.carouselReason : "switch");
        }
    }

    IpcHandler {
        target: "carousel"

        // Opens on the focused screen, facing its active workspace.
        function open(): void {
            controller.openFocused();
        }
        function toggle(): void {
            controller.open ? ShellState.hideCarousel() : controller.openFocused();
        }
        // As a workspace switch would show it.
        function flash(screenName: string, workspaceId: int): void {
            controller.show(screenName, workspaceId, "switch");
        }
        function openOn(screenName: string, workspaceId: int): void {
            controller.show(screenName, workspaceId, "keys");
        }
        function next(): void {
            controller.turn(1);
        }
        function prev(): void {
            controller.turn(-1);
        }
        function hide(): void {
            ShellState.hideCarousel();
        }
        function status(): string {
            return JSON.stringify({
                enabled: controller.enabled,
                screen: ShellState.carouselScreen,
                workspace: ShellState.carouselWorkspace,
                reason: ShellState.carouselReason,
                anchor: ShellState.carouselAnchor
            });
        }
    }
}
