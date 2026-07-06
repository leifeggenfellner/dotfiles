import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/hypr"
import "../../services/wallpaper"

// ── WallpaperPicker ───────────────────────────────────────────
// Per-theme wallpaper browser (D-019): grid of the ACTIVE theme's
// wallpapers only (Theme.wallpapers), current one ringed. Click
// applies via WallpaperCommands (records last-used) and stays open
// for browsing. Opens/closes via ShellState (IPC / keybind), Esc,
// click-outside. Shows only on the focused monitor (HyprState).

PanelWindow {
    id: picker

    required property var modelData
    screen: modelData

    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === picker.screen.name
    readonly property bool open: ShellState.wallpapersOpen && onFocusedScreen

    // Stay mapped through the fade-out so closing is smooth.
    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-wallpapers"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    component WallpaperCard: Rectangle {
        required property var modelData

        readonly property bool isCurrent: modelData === WallpaperState.current

        width: 216
        height: 146
        radius: Theme.metrics.radius.medium
        color: cardMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"
        border.width: isCurrent ? 2 : 1
        border.color: isCurrent ? Theme.colors.accent.primary : Theme.colors.bg.surface1

        Column {
            anchors.centerIn: parent
            spacing: Theme.metrics.space.sm

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 192
                height: 108
                radius: Theme.metrics.radius.small
                color: Theme.colors.bg.sunken
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + modelData
                    sourceSize.width: 400
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.split("/").pop()
                color: isCurrent ? Theme.colors.accent.primary : Theme.colors.fg.muted
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
                elide: Text.ElideMiddle
                width: Math.min(implicitWidth, 192)
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: !WallpaperState.busy
            onClicked: WallpaperCommands.apply(modelData)
        }
    }

    // Scrim: dims the workspace, closes on click-outside.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: picker.open ? 0.45 : 0

        Behavior on opacity {
            MotionAnim {
                spec: picker.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeWallpapers()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: ShellState.closeWallpapers()

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.max(grid.width, header.width) + Theme.metrics.space.lg * 2
            height: header.height + grid.height + status.height + Theme.metrics.space.lg * 3
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: picker.open ? 1 : 0
            scale: picker.open ? 1 : 0.94

            Behavior on opacity {
                MotionAnim {
                    spec: picker.open ? Motion.panelOpen : Motion.panelClose
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: picker.open ? Motion.panelOpen : Motion.panelClose
                }
            }

            // Absorb clicks so they don't fall through to the scrim.
            MouseArea {
                anchors.fill: parent
            }

            Row {
                id: header
                anchors.top: parent.top
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.metrics.space.md

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wallpapers"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.heading
                }

                // Cycle affordance — same command as the keybind/IPC.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Theme.wallpapers.length > 1
                    width: nextLabel.width + Theme.metrics.space.md * 2
                    height: nextLabel.height + Theme.metrics.space.xs * 2
                    radius: Theme.metrics.radius.small
                    color: nextMouse.containsMouse ? Theme.colors.bg.elevated : "transparent"
                    border.width: 1
                    border.color: Theme.colors.bg.surface1

                    Text {
                        id: nextLabel
                        anchors.centerIn: parent
                        text: "next"
                        color: Theme.colors.fg.muted
                        font.family: Theme.typography.families.mono
                        font.pointSize: Theme.typography.sizes.small
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !WallpaperState.busy
                        onClicked: WallpaperCommands.next()
                    }
                }
            }

            Grid {
                id: grid
                anchors.top: header.bottom
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                spacing: Theme.metrics.space.md

                Repeater {
                    model: Theme.wallpapers
                    WallpaperCard {}
                }

                Text {
                    visible: Theme.wallpapers.length === 0
                    text: "theme ships no wallpapers"
                    color: Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.body
                }
            }

            Text {
                id: status
                anchors.top: grid.bottom
                anchors.topMargin: Theme.metrics.space.sm
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                text: WallpaperState.busy ? "applying…" : WallpaperState.error
                color: WallpaperState.error.length > 0 ? Theme.colors.state.danger : Theme.colors.fg.subtle
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
