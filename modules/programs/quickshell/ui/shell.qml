import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        Bar {
            screen: modelData
        }
    }
}
