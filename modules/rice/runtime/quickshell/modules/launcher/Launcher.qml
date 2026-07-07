import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/apps"
import "../../services/hypr"

// ── Launcher ──────────────────────────────────────────────────
// Real app launcher backed by AppsState/DesktopEntries. Opens/closes
// via ShellState (IPC / keybind), Esc, click-outside, or launch.
// Shows only on the focused monitor (HyprState). Theme flavor enters
// through Theme.widgetConfig("launcher") settings (D-023).

PanelWindow {
    id: launcher

    required property var modelData
    screen: modelData

    // Open, and this instance's screen is the focused one (or focus
    // is unknown, e.g. outside a Hyprland session).
    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === launcher.screen.name
    readonly property bool open: ShellState.launcherOpen && onFocusedScreen
    readonly property var settings: Theme.widgetConfig("launcher").settings ?? ({})
    readonly property string placeholder: settings.placeholder ?? "Search applications"
    readonly property var epigraphs: settings.epigraphs ?? ["Type to search applications."]
    readonly property int columns: settings.columns ?? 4
    readonly property int maxResults: settings.maxResults ?? 16
    readonly property string query: searchField.text
    readonly property var results: AppsState.search(query, maxResults)
    property int selectedIndex: results.length > 0 ? 0 : -1

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

    function clampSelection() {
        if (results.length === 0)
            selectedIndex = -1;
        else if (selectedIndex < 0 || selectedIndex >= results.length)
            selectedIndex = 0;
    }

    function activate(index) {
        if (index < 0 || index >= results.length)
            return;
        pressPulse.restart();
        AppsState.launch(results[index].app);
        ShellState.closeLauncher();
    }

    function epigraphText() {
        if (epigraphs.length === 0)
            return "";
        return epigraphs[Math.abs(query.length) % epigraphs.length];
    }

    onResultsChanged: clampSelection()
    onOpenChanged: {
        if (open) {
            searchField.text = "";
            searchField.forceActiveFocus();
            clampSelection();
        }
    }

    SequentialAnimation {
        id: pressPulse
        running: false
        NumberAnimation {
            target: panel
            property: "scale"
            to: 1.025
            duration: Motion.sealPress.duration / 2
            easing.type: Motion.sealPress.easing
        }
        NumberAnimation {
            target: panel
            property: "scale"
            to: 1
            duration: Motion.sealPress.duration / 2
            easing.type: Motion.sealPress.easing
        }
    }

    component AppCard: Rectangle {
        required property var modelData
        required property int index

        readonly property bool selected: index === launcher.selectedIndex

        width: 156
        height: 108
        radius: Theme.metrics.radius.medium
        color: selected ? Theme.colors.bg.elevated : (cardMouse.containsMouse ? Theme.colors.bg.surface1 : "transparent")
        border.width: selected ? 1 : 0
        border.color: Theme.colors.accent.primary

        Column {
            anchors.fill: parent
            anchors.margins: Theme.metrics.space.md
            spacing: Theme.metrics.space.sm

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 38
                height: 38
                radius: Theme.metrics.radius.small
                color: Theme.colors.bg.sunken

                Image {
                    visible: modelData.iconPath.length > 0
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    source: modelData.iconPath
                    sourceSize.width: 56
                    sourceSize.height: 56
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }

                Icon {
                    visible: modelData.iconPath.length === 0
                    anchors.centerIn: parent
                    name: "settings"
                    size: Theme.typography.sizes.heading
                    color: selected ? Theme.colors.accent.primary : Theme.colors.fg.muted
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.name
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: selected ? Theme.colors.accent.primary : Theme.colors.fg.primary
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.subtitle
                visible: text.length > 0
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: launcher.selectedIndex = index
            onClicked: launcher.activate(index)
        }
    }

    // Scrim: dims the workspace, closes on click-outside.
    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: launcher.open ? 0.45 : 0

        Behavior on opacity {
            MotionAnim {
                spec: launcher.open ? Motion.surfaceReveal : Motion.surfaceConceal
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
        Keys.onReturnPressed: launcher.activate(launcher.selectedIndex)
        Keys.onEnterPressed: launcher.activate(launcher.selectedIndex)
        Keys.onUpPressed: {
            if (launcher.results.length > 0)
                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - launcher.columns);
        }
        Keys.onDownPressed: {
            if (launcher.results.length > 0)
                launcher.selectedIndex = Math.min(launcher.results.length - 1, launcher.selectedIndex + launcher.columns);
        }
        Keys.onLeftPressed: {
            if (launcher.results.length > 0)
                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - 1);
        }
        Keys.onRightPressed: {
            if (launcher.results.length > 0)
                launcher.selectedIndex = Math.min(launcher.results.length - 1, launcher.selectedIndex + 1);
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.max(720, grid.width) + Theme.metrics.space.lg * 2
            height: header.height + grid.height + status.height + Theme.metrics.space.lg * 3
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1

            opacity: launcher.open ? 1 : 0
            scale: launcher.open ? 1 : 0.96

            Behavior on opacity {
                MotionAnim {
                    spec: launcher.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: launcher.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }

            // Absorb clicks so they don't fall through to the scrim.
            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: header
                anchors.top: parent.top
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.metrics.space.lg * 2
                spacing: Theme.metrics.space.md

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Applications"
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.display
                    font.pointSize: Theme.typography.sizes.heading
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: 44
                    radius: Theme.metrics.radius.medium
                    color: Theme.colors.bg.sunken
                    border.width: 1
                    border.color: searchField.activeFocus ? Theme.colors.accent.primary : Theme.colors.bg.surface1

                    TextInput {
                        id: searchField
                        anchors.fill: parent
                        anchors.leftMargin: Theme.metrics.space.md
                        anchors.rightMargin: Theme.metrics.space.md
                        verticalAlignment: TextInput.AlignVCenter
                        focus: launcher.open
                        color: Theme.colors.fg.primary
                        selectionColor: Theme.colors.accent.primary
                        selectedTextColor: Theme.colors.bg.sunken
                        font.family: Theme.typography.families.sans
                        font.pointSize: Theme.typography.sizes.body
                        clip: true
                        Keys.onEscapePressed: ShellState.closeLauncher()
                        Keys.onReturnPressed: launcher.activate(launcher.selectedIndex)
                        Keys.onEnterPressed: launcher.activate(launcher.selectedIndex)
                        Keys.onUpPressed: {
                            if (launcher.results.length > 0)
                                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - launcher.columns);
                        }
                        Keys.onDownPressed: {
                            if (launcher.results.length > 0)
                                launcher.selectedIndex = Math.min(launcher.results.length - 1, launcher.selectedIndex + launcher.columns);
                        }
                        Keys.onLeftPressed: {
                            if (launcher.results.length > 0)
                                launcher.selectedIndex = Math.max(0, launcher.selectedIndex - 1);
                        }
                        Keys.onRightPressed: {
                            if (launcher.results.length > 0)
                                launcher.selectedIndex = Math.min(launcher.results.length - 1, launcher.selectedIndex + 1);
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: launcher.placeholder
                            visible: searchField.text.length === 0
                            color: Theme.colors.fg.subtle
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.body
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    text: launcher.query.length === 0 ? launcher.epigraphText() : (launcher.results.length + " result" + (launcher.results.length === 1 ? "" : "s"))
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }

            Grid {
                id: grid
                anchors.top: header.bottom
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                columns: launcher.columns
                spacing: Theme.metrics.space.md

                Repeater {
                    model: launcher.results
                    AppCard {}
                }

                Text {
                    visible: launcher.results.length === 0
                    width: 640
                    text: AppsState.apps.length === 0 ? "no desktop entries found" : "no matches"
                    color: Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.body
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Text {
                id: status
                anchors.top: grid.bottom
                anchors.topMargin: Theme.metrics.space.sm
                anchors.horizontalCenter: parent.horizontalCenter
                height: implicitHeight
                text: AppsState.error
                color: Theme.colors.state.danger
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
