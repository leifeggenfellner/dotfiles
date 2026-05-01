import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/hypr"

// ── Launcher ──────────────────────────────────────────────────
// MVP: static grid of dummy apps. Opens/closes via ShellState
// (IPC / keybind), Esc, or click-outside. No search, no real
// apps yet — those arrive with the launcher's service phase.
// Shows only on the focused monitor (HyprState).

PanelWindow {
    id: launcher

    required property var modelData
    screen: modelData

    // Open, and this instance's screen is the focused one (or focus
    // is unknown, e.g. outside a Hyprland session).
    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === launcher.screen.name
    readonly property bool open: ShellState.launcherOpen && onFocusedScreen

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    readonly property var apps: [
        { name: "Terminal", icon: "terminal" },
        { name: "Files", icon: "files" },
        { name: "Browser", icon: "browser" },
        { name: "Editor", icon: "editor" },
        { name: "Music", icon: "music" },
        { name: "Settings", icon: "settings" },
        { name: "Mail", icon: "mail" },
        { name: "Chat", icon: "chat" },
        { name: "Photos", icon: "photos" },
        { name: "Calendar", icon: "calendar" },
        { name: "Notes", icon: "notes" },
        { name: "Monitor", icon: "monitor" }
    ]

    component AppTile: Rectangle {
        required property var modelData

        width: 120
        height: 96
        radius: Theme.metrics.radius.medium
        color: tileMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"

        Column {
            anchors.centerIn: parent
            spacing: Theme.metrics.space.sm

            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: modelData.icon
                size: Theme.typography.sizes.heading + 6
                color: tileMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.name
                color: Theme.colors.fg.primary
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            // Dummy apps: activating just closes the launcher.
            onClicked: ShellState.closeLauncher()
        }
    }

    // Scrim: dims the workspace, closes on click-outside.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: launcher.open ? 0.45 : 0

        Behavior on opacity {
            MotionAnim {
                spec: launcher.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeLauncher()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closeLauncher()

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: grid.width + Theme.metrics.space.lg * 2
            height: title.height + grid.height + Theme.metrics.space.lg * 3
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: launcher.open ? 1 : 0
            scale: launcher.open ? 1 : 0.94

            Behavior on opacity {
                MotionAnim {
                    spec: launcher.open ? Motion.panelOpen : Motion.panelClose
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: launcher.open ? Motion.panelOpen : Motion.panelClose
                }
            }

            // Absorb clicks so they don't fall through to the scrim.
            MouseArea {
                anchors.fill: parent
            }

            Text {
                id: title
                anchors.top: parent.top
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Applications"
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.heading
            }

            Grid {
                id: grid
                anchors.top: title.bottom
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 4
                spacing: Theme.metrics.space.md

                Repeater {
                    model: launcher.apps
                    AppTile {}
                }
            }
        }
    }
}
