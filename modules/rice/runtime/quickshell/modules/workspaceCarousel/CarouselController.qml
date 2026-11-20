import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../../services/hypr"

// ── CarouselController ────────────────────────────────────────
// Opens and turns the full-screen workspace carousel (D-069). The
// surface only draws ShellState's carousel fields; this writes them.
// Off unless the theme sets widgets.workspaces.settings.carousel.
//
// It opens only on purpose (Super+Tab → `toggle`), on the focused
// screen, facing that screen's workspace. A workspace switch while it
// is open turns it to the new card instead of closing it.
//
// External control: quickshell -c rice ipc call carousel <fn>

Item {
    id: controller

    readonly property var settings: Theme.widgetConfig("workspaces").settings ?? ({})
    readonly property bool enabled: (settings.carousel ?? null) !== null
    readonly property var items: settings.items ?? []
    readonly property bool open: ShellState.carouselScreen.length > 0

    function has(workspaceId) {
        return items.some(i => i.id === workspaceId);
    }

    // Faces the screen's workspace, or the first card when that
    // workspace has none.
    function openOn(screenName, workspaceId) {
        if (!enabled || !screenName || items.length === 0)
            return;
        ShellState.showCarousel(screenName, has(workspaceId) ? workspaceId : items[0].id);
    }

    function openFocused() {
        const screenName = HyprState.focusedScreenName || (Quickshell.screens[0]?.name ?? "");
        openOn(screenName, HyprState.activeWorkspaceForScreen(screenName));
    }

    function turn(steps) {
        if (!open)
            return;
        const at = items.findIndex(i => i.id === ShellState.carouselWorkspace);
        const next = Math.max(0, Math.min(items.length - 1, at + steps));
        ShellState.showCarousel(ShellState.carouselScreen, items[next].id);
    }

    onEnabledChanged: if (!enabled)
        ShellState.hideCarousel()

    Connections {
        target: controller.open ? HyprState : null
        function onWorkspaceSwitched(screenName, workspaceId) {
            if (screenName === ShellState.carouselScreen && controller.has(workspaceId))
                ShellState.showCarousel(screenName, workspaceId);
        }
    }

    IpcHandler {
        target: "carousel"

        function open(): void {
            controller.openFocused();
        }
        function toggle(): void {
            controller.open ? ShellState.hideCarousel() : controller.openFocused();
        }
        function close(): void {
            ShellState.hideCarousel();
        }
        function openOn(screenName: string, workspaceId: int): void {
            controller.openOn(screenName, workspaceId);
        }
        function next(): void {
            controller.turn(1);
        }
        function prev(): void {
            controller.turn(-1);
        }
        function status(): string {
            return JSON.stringify({
                enabled: controller.enabled,
                screen: ShellState.carouselScreen,
                workspace: ShellState.carouselWorkspace
            });
        }
    }
}
