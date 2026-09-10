import Quickshell
import QtQuick
import "./core"
import "./modules/ambient"
import "./modules/bar"
import "./modules/launcher"
import "./modules/dashboard"
import "./modules/sound"
import "./modules/osd"
import "./modules/notifications"
import "./modules/satchel"
import "./modules/switcher"
import "./modules/wallpapers"
import "./modules/debug"
import "./modules/lore"

// ── shell ─────────────────────────────────────────────────────
// Pure compositor: instantiates one of each surface per screen.
// No feature logic lives here; visibility is owned by ShellState.

ShellRoot {
    id: root

    component SurfaceLoader: Loader {
        required property var modelData
        required property bool requested

        active: requested || (item !== null && item.visible)
    }

    NotificationIpc {}

    WallpaperIpc {}

    AmbientController {}

    SoundController {}

    LoreController {}

    OsdController {}

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: ambientLoader
            requested: ShellState.ambientActive
            sourceComponent: AmbientLayer {
                modelData: ambientLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: idleLoader
            requested: ShellState.idleApproaching
            sourceComponent: IdleOverlay {
                modelData: idleLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        LoreOverlay {}
    }

    Variants {
        model: Quickshell.screens
        TopBar {}
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: popoutLoader
            requested: ShellState.activePopout.length > 0
            sourceComponent: BarPopout {
                modelData: popoutLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: launcherLoader
            requested: ShellState.launcherOpen
            sourceComponent: Launcher {
                modelData: launcherLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        DashboardLoader {}
    }

    Variants {
        model: Quickshell.screens
        Osd {}
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: notificationCenterLoader
            requested: ShellState.notificationsOpen
            sourceComponent: NotificationCenter {
                modelData: notificationCenterLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: satchelLoader
            requested: ShellState.satchelOpen
            sourceComponent: Satchel {
                modelData: satchelLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        Toasts {}
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: switcherLoader
            requested: ShellState.switcherOpen
            sourceComponent: ThemeSwitcher {
                modelData: switcherLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: wallpaperLoader
            requested: ShellState.wallpapersOpen
            sourceComponent: WallpaperPicker {
                modelData: wallpaperLoader.modelData
            }
        }
    }

    Variants {
        model: Quickshell.screens
        SurfaceLoader {
            id: debugLoader
            requested: ShellState.debugVisible
            sourceComponent: DebugOverlay {
                modelData: debugLoader.modelData
            }
        }
    }
}
