pragma Singleton
import QtQuick
import Quickshell.Io

// ── ShellState ────────────────────────────────────────────────
// UI-only shell state: which surfaces are visible. System state
// lives in services/; nothing here touches the OS.
//
// Surfaces bind visibility to these flags and never self-show.
// External control: quickshell -p <runtime> ipc call shell <fn>

Item {
    id: shell

    property bool topBarVisible: true
    property bool launcherOpen: false
    property bool dashboardOpen: false
    property bool switcherOpen: false
    property bool notificationsOpen: false
    property bool osdVisible: false
    property bool debugVisible: false

    // Single-open popout (L-002): the widgetId whose popout is up.
    property string activePopout: ""

    function togglePopout(widgetId) {
        activePopout = (activePopout === widgetId) ? "" : widgetId;
    }
    function closePopout() {
        activePopout = "";
    }

    // Center-stage surfaces are mutually exclusive.
    function openLauncher() {
        dashboardOpen = false;
        switcherOpen = false;
        activePopout = "";
        launcherOpen = true;
    }
    function closeLauncher() {
        launcherOpen = false;
    }
    function toggleLauncher() {
        launcherOpen ? closeLauncher() : openLauncher();
    }

    function toggleDashboard() {
        launcherOpen = false;
        switcherOpen = false;
        dashboardOpen = !dashboardOpen;
    }
    function toggleSwitcher() {
        launcherOpen = false;
        dashboardOpen = false;
        activePopout = "";
        switcherOpen = !switcherOpen;
    }
    function closeSwitcher() {
        switcherOpen = false;
    }
    function toggleNotifications() {
        notificationsOpen = !notificationsOpen;
    }
    function toggleOsd() {
        osdVisible = !osdVisible;
    }
    function toggleTopBar() {
        topBarVisible = !topBarVisible;
    }
    function toggleDebug() {
        debugVisible = !debugVisible;
    }

    IpcHandler {
        target: "shell"

        function toggleLauncher(): void {
            shell.toggleLauncher();
        }
        function toggleDashboard(): void {
            shell.toggleDashboard();
        }
        function toggleSwitcher(): void {
            shell.toggleSwitcher();
        }
        function toggleNotifications(): void {
            shell.toggleNotifications();
        }
        function toggleOsd(): void {
            shell.toggleOsd();
        }
        function toggleTopBar(): void {
            shell.toggleTopBar();
        }
        function toggleDebug(): void {
            shell.toggleDebug();
        }
        function togglePopout(widgetId: string): void {
            shell.togglePopout(widgetId);
        }
    }
}
