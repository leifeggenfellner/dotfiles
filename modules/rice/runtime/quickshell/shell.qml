import Quickshell
import "./modules/bar"
import "./modules/launcher"
import "./modules/dashboard"
import "./modules/osd"
import "./modules/notifications"
import "./modules/debug"

// ── shell ─────────────────────────────────────────────────────
// Pure compositor: instantiates one of each surface per screen.
// No feature logic lives here; visibility is owned by ShellState.

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        TopBar {}
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
        DebugOverlay {}
    }
}
