import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/hypr"
import "../../services/rice"

// ── ThemeSwitcher ─────────────────────────────────────────────
// Rice switcher (D-003): one card per Nix-built theme from the
// index (preview + display name), active theme ringed. Click
// switches via RiceState → rice-switch; the shell re-themes live
// through the pointer watch, so the open switcher itself recolors.
// Opens/closes via ShellState (IPC / keybind), Esc, click-outside.
// Shows only on the focused monitor (HyprState).

PanelWindow {
    id: switcher

    required property var modelData
    screen: modelData

    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === switcher.screen.name
    readonly property bool open: ShellState.switcherOpen && onFocusedScreen

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    component ThemeCard: Rectangle {
        required property var modelData

        readonly property bool isActive: modelData.name === Theme.activeName

        width: 200
        height: 158
        radius: Theme.metrics.radius.medium
        color: cardMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"
        border.width: isActive ? 2 : 1
        border.color: isActive ? Theme.colors.accent.primary : Theme.colors.bg.surface1

        Column {
            anchors.centerIn: parent
            spacing: Theme.metrics.space.sm

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 176
                height: 99
                radius: Theme.metrics.radius.small
                color: Theme.colors.bg.sunken
                clip: true

                Image {
                    anchors.fill: parent
                    source: modelData.preview
                    sourceSize.width: 352
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.displayName
                color: isActive ? Theme.colors.accent.primary : Theme.colors.fg.primary
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !RiceState.busy
            onClicked: {
                if (!isActive)
                    RiceState.switchTo(modelData.name);
            }
        }
    }

    // Scrim: dims the workspace, closes on click-outside.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: switcher.open ? 0.45 : 0

        Behavior on opacity {
            MotionAnim {
                spec: switcher.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeSwitcher()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closeSwitcher()

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: row.width + Theme.metrics.space.lg * 2
            height: title.height + row.height + status.height + Theme.metrics.space.lg * 3
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: switcher.open ? 1 : 0
            scale: switcher.open ? 1 : 0.94

            Behavior on opacity {
                MotionAnim {
                    spec: switcher.open ? Motion.panelOpen : Motion.panelClose
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: switcher.open ? Motion.panelOpen : Motion.panelClose
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
                text: "Themes"
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.display
                font.pointSize: Theme.typography.sizes.heading
            }

            Row {
                id: row
                anchors.top: title.bottom
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.metrics.space.md

                Repeater {
                    model: Theme.catalog
                    ThemeCard {}
                }

                // Index missing (dev run without rebuild): say so
                // instead of rendering an empty shell.
                Text {
                    visible: Theme.catalog.length === 0
                    text: "no theme index — rebuild with rice.enable"
                    color: Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.body
                }
            }

            Text {
                id: status
                anchors.top: row.bottom
                anchors.topMargin: Theme.metrics.space.sm
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                text: RiceState.busy ? "switching…" : RiceState.error
                color: RiceState.error.length > 0 ? Theme.colors.state.danger : Theme.colors.fg.subtle
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
