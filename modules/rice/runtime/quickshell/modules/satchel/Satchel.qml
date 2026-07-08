import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../components/effects"
import "../../services/clipboard"
import "../../services/hypr"
import "../../services/prefs"

// ── Satchel ──────────────────────────────────────────────────
// Clipboard history surface backed by ClipboardState/cliphist.
// Opens/closes via ShellState (IPC / keybind), Esc, click-outside.
// Pinned entries are stored in PrefsState extras under satchel.sealed.

PanelWindow {
    id: satchel

    required property var modelData
    screen: modelData

    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === satchel.screen.name
    readonly property bool open: ShellState.satchelOpen && onFocusedScreen
    readonly property var settings: Theme.widgetConfig("satchel").settings ?? ({})
    readonly property string title: settings.title ?? "Clipboard"
    readonly property string placeholder: settings.placeholder ?? "Search clipboard history"
    readonly property string emptyText: settings.emptyText ?? "Clipboard history is empty."
    readonly property string sealedLabel: settings.sealedLabel ?? "sealed"
    readonly property int maxResults: settings.maxResults ?? 24
    readonly property var sealed: PrefsState.extra("satchel", "sealed", ({}))
    readonly property var results: ClipboardState.search(searchField.text, maxResults)
    property int selectedIndex: results.length > 0 ? 0 : -1

    visible: open || panel.opacity > 0.01

    WlrLayershell.namespace: "rice-satchel"
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

    function isSealed(entry) {
        return entry && sealed[entry.key] !== undefined;
    }

    function toggleSeal(entry) {
        if (!entry)
            return;
        const next = JSON.parse(JSON.stringify(sealed));
        if (next[entry.key] !== undefined)
            delete next[entry.key];
        else
            next[entry.key] = {
                preview: entry.preview,
                kind: entry.kind
            };
        PrefsState.setExtra("satchel", "sealed", next);
    }

    function activate(index) {
        if (index < 0 || index >= results.length)
            return;
        ClipboardState.copy(results[index]);
        ShellState.closeSatchel();
    }

    onResultsChanged: clampSelection()
    onOpenChanged: {
        if (open) {
            searchField.text = "";
            ClipboardState.clearError();
            ClipboardState.refresh();
            keyScope.forceActiveFocus();
            clampSelection();
        }
    }

    component EntryCard: Rectangle {
        id: card

        required property var modelData
        required property int index

        readonly property bool selected: index === satchel.selectedIndex
        readonly property bool sealedEntry: satchel.isSealed(modelData)

        width: listColumn.width
        height: Math.max(74, content.height + Theme.metrics.space.md * 2)
        radius: Theme.metrics.radius.medium
        color: selected ? Theme.colors.bg.elevated : (cardMouse.containsMouse ? Theme.colors.bg.surface1 : Theme.colors.bg.sunken)
        border.width: selected || sealedEntry ? 1 : 0
        border.color: sealedEntry ? Theme.colors.accent.primary : Theme.colors.bg.surface1

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            onEntered: satchel.selectedIndex = index
            onClicked: satchel.activate(index)
        }

        Rectangle {
            width: 4
            height: parent.height - Theme.metrics.space.md
            anchors.left: parent.left
            anchors.leftMargin: Theme.metrics.space.sm
            anchors.verticalCenter: parent.verticalCenter
            radius: 2
            color: sealedEntry ? Theme.colors.accent.primary : Theme.colors.fg.subtle
        }

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: controls.left
            anchors.leftMargin: Theme.metrics.space.lg
            anchors.rightMargin: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Row {
                width: parent.width
                spacing: Theme.metrics.space.sm

                Text {
                    text: modelData.kind
                    color: Theme.colors.fg.subtle
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }
                Text {
                    visible: sealedEntry
                    text: satchel.sealedLabel
                    color: Theme.colors.accent.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }

            Text {
                width: parent.width
                text: modelData.preview
                color: Theme.colors.fg.primary
                elide: Text.ElideRight
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }
        }

        Row {
            id: controls
            anchors.right: parent.right
            anchors.rightMargin: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.md

            Icon {
                name: sealedEntry ? "pin" : "pin-off"
                size: Theme.typography.sizes.body
                color: sealMouse.containsMouse || sealedEntry ? Theme.colors.accent.primary : Theme.colors.fg.subtle

                MouseArea {
                    id: sealMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.metrics.space.sm
                    hoverEnabled: true
                    onClicked: satchel.toggleSeal(card.modelData)
                }
            }

            Icon {
                name: "trash"
                size: Theme.typography.sizes.body
                color: deleteMouse.containsMouse ? Theme.colors.state.warn : Theme.colors.fg.subtle

                MouseArea {
                    id: deleteMouse
                    anchors.fill: parent
                    anchors.margins: -Theme.metrics.space.sm
                    hoverEnabled: true
                    enabled: !ClipboardState.busy
                    onClicked: ClipboardState.deleteEntry(card.modelData)
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg.sunken
        opacity: satchel.open ? 0.45 : 0

        Behavior on opacity {
            MotionAnim {
                spec: satchel.open ? Motion.surfaceReveal : Motion.surfaceConceal
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: ShellState.closeSatchel()
        }
    }

    FocusScope {
        id: keyScope

        anchors.fill: parent
        focus: satchel.open
        Keys.onEscapePressed: ShellState.closeSatchel()
        Keys.onReturnPressed: satchel.activate(satchel.selectedIndex)
        Keys.onEnterPressed: satchel.activate(satchel.selectedIndex)
        Keys.onUpPressed: {
            if (satchel.results.length > 0)
                satchel.selectedIndex = Math.max(0, satchel.selectedIndex - 1);
        }
        Keys.onDownPressed: {
            if (satchel.results.length > 0)
                satchel.selectedIndex = Math.min(satchel.results.length - 1, satchel.selectedIndex + 1);
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_P && satchel.selectedIndex >= 0) {
                satchel.toggleSeal(satchel.results[satchel.selectedIndex]);
                event.accepted = true;
            }
            if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) && satchel.selectedIndex >= 0) {
                ClipboardState.deleteEntry(satchel.results[satchel.selectedIndex]);
                event.accepted = true;
            }
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: 660
            height: Math.min(620, header.height + listFrame.height + status.height + Theme.metrics.space.lg * 3)
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1
            clip: true

            opacity: satchel.open ? 1 : 0
            scale: satchel.open ? 1 : 0.96

            Behavior on opacity {
                MotionAnim {
                    spec: satchel.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }
            Behavior on scale {
                MotionAnim {
                    spec: satchel.open ? Motion.surfaceReveal : Motion.surfaceConceal
                }
            }

            InkReveal {
                anchors.fill: parent
                open: satchel.open
                tint: Theme.colors.fg.subtle
            }

            MouseArea {
                anchors.fill: parent
            }

            Column {
                anchors.fill: parent
                anchors.margins: Theme.metrics.space.lg
                spacing: Theme.metrics.space.md

                Column {
                    id: header
                    width: parent.width
                    spacing: Theme.metrics.space.md

                    Text {
                        text: satchel.title
                        color: Theme.colors.fg.primary
                        font.family: Theme.typography.families.display
                        font.pointSize: Theme.typography.sizes.heading
                    }

                    Row {
                        id: searchRow
                        width: parent.width
                        spacing: Theme.metrics.space.md

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "clipboard"
                            color: Theme.colors.accent.primary
                        }

                        Rectangle {
                            width: searchRow.width - Theme.typography.sizes.icon - searchRow.spacing
                            height: 36
                            radius: Theme.metrics.radius.small
                            color: Theme.colors.bg.sunken
                            border.width: 1
                            border.color: searchField.activeFocus ? Theme.colors.accent.primary : Theme.colors.bg.surface1

                            TextInput {
                                id: searchField
                                anchors.fill: parent
                                anchors.leftMargin: Theme.metrics.space.md
                                anchors.rightMargin: Theme.metrics.space.md
                                verticalAlignment: TextInput.AlignVCenter
                                color: Theme.colors.fg.primary
                                selectionColor: Theme.colors.accent.primary
                                selectedTextColor: Theme.colors.bg.base
                                font.family: Theme.typography.families.sans
                                font.pointSize: Theme.typography.sizes.body
                                clip: true

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: searchField.text.length === 0 && !searchField.activeFocus
                                    text: satchel.placeholder
                                    color: Theme.colors.fg.subtle
                                    font.family: Theme.typography.families.sans
                                    font.pointSize: Theme.typography.sizes.body
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: listFrame
                    width: parent.width
                    height: 420
                    radius: Theme.metrics.radius.medium
                    color: Theme.colors.bg.base
                    border.width: 1
                    border.color: Theme.colors.bg.surface1
                    clip: true

                    Flickable {
                        anchors.fill: parent
                        anchors.margins: Theme.metrics.space.sm
                        contentWidth: width
                        contentHeight: listColumn.height
                        clip: true

                        Column {
                            id: listColumn
                            width: parent.width
                            spacing: Theme.metrics.space.sm

                            Repeater {
                                model: satchel.results
                                EntryCard {}
                            }

                            Text {
                                visible: satchel.results.length === 0
                                width: parent.width
                                height: listFrame.height - Theme.metrics.space.md * 2
                                text: ClipboardState.busy ? "reading history..." : satchel.emptyText
                                color: Theme.colors.fg.subtle
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: Theme.typography.families.sans
                                font.pointSize: Theme.typography.sizes.body
                            }
                        }
                    }
                }

                Text {
                    id: status
                    width: parent.width
                    height: implicitHeight
                    text: ClipboardState.error.length > 0 ? ClipboardState.error : (ClipboardState.busy ? "working..." : "Enter copies / P seals / Del forgets")
                    color: ClipboardState.error.length > 0 ? Theme.colors.state.danger : Theme.colors.fg.subtle
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }
}
