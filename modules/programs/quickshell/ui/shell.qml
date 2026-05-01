import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "./components" as Components
import "./modules/bar" as BarModules

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens
        Bar {
            // rightWidgets intentionally empty until Phase 1 descriptors are built
        }
    }

    Variants {
        model: Quickshell.screens
        PowerSigilPopup {}
    }

    Variants {
        model: Quickshell.screens
        ConnectionRitualPopup {}
    }
}
