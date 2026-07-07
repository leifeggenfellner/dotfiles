import Quickshell
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

// ── shell ─────────────────────────────────────────────────────
// Pure compositor: instantiates one of each surface per screen.
// No feature logic lives here; visibility is owned by ShellState.

ShellRoot {
    id: root

    NotificationIpc {}

    WallpaperIpc {}

    AmbientController {}

    SoundController {}

    Variants {
        model: Quickshell.screens
        AmbientLayer {}
    }

    Variants {
        model: Quickshell.screens
        TopBar {}
    }

    Variants {
        model: Quickshell.screens
        BarPopout {}
    }

    Variants {
        model: Quickshell.screens
        Launcher {}
    }

    Variants {
        model: Quickshell.screens
        Dashboard {}
    }

    Variants {
        model: Quickshell.screens
        Osd {}
    }

    Variants {
        model: Quickshell.screens
        NotificationCenter {}
    }

    Variants {
        model: Quickshell.screens
        Satchel {}
    }

    Variants {
        model: Quickshell.screens
        Toasts {}
    }

    Variants {
        model: Quickshell.screens
        ThemeSwitcher {}
    }

    Variants {
        model: Quickshell.screens
        WallpaperPicker {}
    }

    Variants {
        model: Quickshell.screens
        DebugOverlay {}
    }
}
