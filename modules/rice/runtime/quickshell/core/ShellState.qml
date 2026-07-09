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
    property bool wallpapersOpen: false
    property bool satchelOpen: false
    property bool notificationsOpen: false
    property bool osdVisible: false
    property string osdKind: "volume"
    property int osdSerial: 0
    property bool debugVisible: false

    // ── Ambient & motion flags (D-021/D-022) ──────────────────
    // Pushed by modules/ambient/AmbientController: the policy needs
    // services (prefs, power, compositor), which nothing below the
    // modules layer may import. Core and components only READ these.
    property bool reduceMotion: false
    property bool ambientActive: false
    property bool idleApproaching: false
    property bool soundMuted: true
    property bool doNotDisturb: false

    // ── Flavor events (D-030) ────────────────────────────────
    // Runtime-owned garnish triggered by modules/lore and surfaces.
    // Themes provide only settings text/phrases; shell state carries
    // the transient event edge for overlays to observe.
    property int flavorEventSerial: 0
    property string flavorEventText: ""
    property string flavorEventKind: ""
    property int fogSurgeSerial: 0

    function triggerFlavorEvent(text, kind, surge) {
        if (!text || text.length === 0)
            return;
        flavorEventText = text;
        flavorEventKind = kind && kind.length > 0 ? kind : "flavor";
        flavorEventSerial++;
        if (surge)
            triggerFogSurge();
    }

    function triggerFogSurge() {
        fogSurgeSerial++;
    }

    // One-shot startup reveal: flips shortly after load so surface
    // contents fade in (Motion.awaken) instead of popping. UI binds
    // to the flag; with motion disabled the reveal is instant.
    property bool awakened: false
    Timer {
        interval: 120
        running: !shell.awakened
        onTriggered: shell.awakened = true
    }

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
        wallpapersOpen = false;
        satchelOpen = false;
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
        wallpapersOpen = false;
        satchelOpen = false;
        activePopout = "";
        dashboardOpen = !dashboardOpen;
    }
    function closeDashboard() {
        dashboardOpen = false;
    }
    function toggleSwitcher() {
        launcherOpen = false;
        dashboardOpen = false;
        wallpapersOpen = false;
        satchelOpen = false;
        activePopout = "";
        switcherOpen = !switcherOpen;
    }
    function closeSwitcher() {
        switcherOpen = false;
    }
    function toggleWallpapers() {
        launcherOpen = false;
        dashboardOpen = false;
        switcherOpen = false;
        satchelOpen = false;
        activePopout = "";
        wallpapersOpen = !wallpapersOpen;
    }
    function closeWallpapers() {
        wallpapersOpen = false;
    }
    function toggleSatchel() {
        launcherOpen = false;
        dashboardOpen = false;
        switcherOpen = false;
        wallpapersOpen = false;
        activePopout = "";
        satchelOpen = !satchelOpen;
    }
    function closeSatchel() {
        satchelOpen = false;
    }
    function toggleNotifications() {
        notificationsOpen = !notificationsOpen;
    }
    function showOsd(kind) {
        osdKind = kind === "brightness" ? "brightness" : "volume";
        osdVisible = true;
        osdSerial++;
    }
    function hideOsd() {
        osdVisible = false;
    }
    function toggleOsd() {
        osdVisible ? hideOsd() : showOsd(osdKind);
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
        function closeDashboard(): void {
            shell.closeDashboard();
        }
        function toggleSwitcher(): void {
            shell.toggleSwitcher();
        }
        function toggleWallpapers(): void {
            shell.toggleWallpapers();
        }
        function toggleSatchel(): void {
            shell.toggleSatchel();
        }
        function closeSatchel(): void {
            shell.closeSatchel();
        }
        function toggleNotifications(): void {
            shell.toggleNotifications();
        }
        function toggleOsd(): void {
            shell.toggleOsd();
        }
        function showOsd(kind: string): void {
            shell.showOsd(kind);
        }
        function hideOsd(): void {
            shell.hideOsd();
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
