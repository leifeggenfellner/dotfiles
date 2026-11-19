import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../components/effects"
import "../../services/apps"
import "../../services/hypr"
import "../../services/prefs"
import "../../utils"

// ── Launcher ──────────────────────────────────────────────────
// Real app launcher backed by AppsState/DesktopEntries. Opens/closes
// via ShellState (IPC / keybind), Esc, click-outside, or launch.
// Shows only on the focused monitor (HyprState). Theme flavor enters
// through Theme.widgetConfig("launcher") settings (D-023).
// The top result is the focus card; the rest follow as a list. Launches
// are remembered as frecency in PrefsState extras (launcher.history), so
// used apps lead an empty query and win close matches.

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
    readonly property var incantationConfig: settings.incantations ?? ({})
    readonly property var incantations: incantationConfig.entries ?? []
    readonly property int maxResults: settings.maxResults ?? 16
    readonly property int visibleRows: settings.visibleRows ?? 7
    readonly property string query: searchField.text
    // Scored at open time, so ranking holds still while the panel is up.
    property real openedAt: Date.now()
    readonly property var history: PrefsState.extra("launcher", "history", ({}))
    readonly property var usage: Frecency.scores(history, openedAt)
    readonly property var results: AppsState.search(query, maxResults, usage)
    readonly property var focusRow: results.length > 0 ? results[0] : null
    property int selectedIndex: results.length > 0 ? 0 : -1
    property string _lastIncantationKey: ""

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
        const row = results[index];
        PrefsState.setExtra("launcher", "history", Frecency.record(history, row.id, Date.now()));
        AppsState.launch(row.app);
        ShellState.closeLauncher();
    }

    function moveSelection(step) {
        if (results.length > 0)
            selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + step));
    }

    function epigraphText() {
        if (epigraphs.length === 0)
            return "";
        return epigraphs[Math.abs(query.length) % epigraphs.length];
    }

    function normalizePhrase(value) {
        return String(value ?? "").trim().toLowerCase().replace(/\s+/g, " ");
    }

    function maybeTriggerIncantation() {
        if (!open || incantationConfig.enabled !== true) {
            _lastIncantationKey = "";
            return;
        }

        const normalizedQuery = normalizePhrase(query);
        if (normalizedQuery.length === 0) {
            _lastIncantationKey = "";
            return;
        }

        for (const entry of incantations) {
            if ((entry.enabled ?? true) === false)
                continue;
            const normalizedPhrase = normalizePhrase(entry.phrase);
            if (normalizedPhrase.length === 0 || normalizedPhrase !== normalizedQuery)
                continue;

            const key = normalizedPhrase + "|" + (entry.event ?? "incantation");
            if (_lastIncantationKey === key)
                return;

            _lastIncantationKey = key;
            Sound.play(entry.sound ?? "");
            ShellState.triggerFlavorEvent(entry.text ?? entry.message ?? "", entry.event ?? "incantation", entry.surge ?? true);
            if (entry.closeOnMatch === true)
                ShellState.closeLauncher();
            return;
        }

        _lastIncantationKey = "";
    }

    onResultsChanged: clampSelection()
    onQueryChanged: maybeTriggerIncantation()
    onOpenChanged: {
        if (open) {
            openedAt = Date.now();
            searchField.text = "";
            _lastIncantationKey = "";
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

    component AppIcon: Item {
        required property var row
        required property bool selected
        property int box: 38

        width: box
        height: box

        Rectangle {
            anchors.fill: parent
            radius: Theme.metrics.radius.small
            color: Theme.colors.bg.sunken
        }

        Image {
            visible: row.iconPath.length > 0
            anchors.centerIn: parent
            width: Math.round(box * 0.74)
            height: width
            source: row.iconPath
            sourceSize.width: width * 2
            sourceSize.height: width * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Icon {
            visible: row.iconPath.length === 0
            anchors.centerIn: parent
            name: "settings"
            size: Math.round(box * 0.5)
            color: selected ? Theme.colors.accent.primary : Theme.colors.fg.muted
        }
    }

    // The top result, large: what Enter launches when nothing else is picked.
    component FocusCard: Rectangle {
        id: card
        required property var row
        readonly property bool selected: launcher.selectedIndex === 0

        height: 112
        radius: Theme.metrics.radius.medium
        color: selected ? Theme.colors.bg.elevated : Theme.colors.bg.surface1
        border.width: selected ? 1 : 0
        border.color: Theme.colors.accent.primary

        AppIcon {
            id: focusIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.metrics.space.lg
            anchors.verticalCenter: parent.verticalCenter
            row: card.row
            selected: card.selected
            box: 72
        }

        Column {
            anchors.left: focusIcon.right
            anchors.leftMargin: Theme.metrics.space.lg
            anchors.right: enterHint.left
            anchors.rightMargin: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.metrics.space.xs

            Text {
                width: parent.width
                text: card.row.name
                color: card.selected ? Theme.colors.accent.primary : Theme.colors.fg.primary
                font.family: Theme.typography.families.display
                font.pointSize: Math.round(Theme.typography.sizes.heading * 1.15)
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: card.row.subtitle
                visible: text.length > 0
                color: Theme.colors.fg.muted
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                text: card.row.comment
                visible: text.length > 0 && text !== card.row.subtitle
                color: Theme.colors.fg.subtle
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.small
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }

        Text {
            id: enterHint
            anchors.right: parent.right
            anchors.rightMargin: Theme.metrics.space.lg
            anchors.verticalCenter: parent.verticalCenter
            text: "\u21b5"
            opacity: card.selected ? 1 : 0.4
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.heading
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: launcher.selectedIndex = 0
            onClicked: launcher.activate(0)
        }
    }

    component ResultRow: Rectangle {
        id: resultRow
        required property var modelData
        required property int index
        // Row 0 of the list is result 1: the focus card holds result 0.
        readonly property int resultIndex: index + 1
        readonly property bool selected: resultIndex === launcher.selectedIndex

        width: ListView.view ? ListView.view.width : 0
        height: launcher.rowHeight
        radius: Theme.metrics.radius.small
        color: selected ? Theme.colors.bg.elevated : (rowMouse.containsMouse ? Theme.colors.bg.surface1 : "transparent")

        AppIcon {
            id: rowIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.metrics.space.sm
            anchors.verticalCenter: parent.verticalCenter
            row: resultRow.modelData
            selected: resultRow.selected
            box: 28
        }

        Text {
            id: rowName
            anchors.left: rowIcon.right
            anchors.leftMargin: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width * 0.45)
            text: resultRow.modelData.name
            color: resultRow.selected ? Theme.colors.accent.primary : Theme.colors.fg.primary
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.body
            elide: Text.ElideRight
        }

        Text {
            anchors.left: rowName.right
            anchors.leftMargin: Theme.metrics.space.md
            anchors.right: parent.right
            anchors.rightMargin: Theme.metrics.space.md
            anchors.verticalCenter: parent.verticalCenter
            text: resultRow.modelData.subtitle
            color: Theme.colors.fg.subtle
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
            elide: Text.ElideRight
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.stateChange.duration
                easing.type: Motion.stateChange.easing
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            onEntered: launcher.selectedIndex = resultRow.resultIndex
            onClicked: launcher.activate(resultRow.resultIndex)
        }
    }

    readonly property int rowHeight: 40

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
        Keys.onUpPressed: launcher.moveSelection(-1)
        Keys.onDownPressed: launcher.moveSelection(1)
        Keys.onTabPressed: launcher.moveSelection(1)
        Keys.onBacktabPressed: launcher.moveSelection(-1)

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: 720 + Theme.metrics.space.lg * 2
            height: header.height + body.height + status.height + Theme.metrics.space.lg * 3
            radius: Theme.metrics.radius.large
            color: Theme.colors.bg.mantle
            border.width: 1
            border.color: Theme.colors.bg.surface1
            clip: true

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

            InkReveal {
                anchors.fill: parent
                open: launcher.open
                tint: Theme.colors.fg.subtle
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
                        Keys.onUpPressed: launcher.moveSelection(-1)
                        Keys.onDownPressed: launcher.moveSelection(1)
                        Keys.onTabPressed: launcher.moveSelection(1)
                        Keys.onBacktabPressed: launcher.moveSelection(-1)

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

            Column {
                id: body
                anchors.top: header.bottom
                anchors.topMargin: Theme.metrics.space.lg
                anchors.horizontalCenter: parent.horizontalCenter
                width: 720
                spacing: Theme.metrics.space.sm

                FocusCard {
                    visible: launcher.focusRow !== null
                    width: parent.width
                    row: launcher.focusRow ?? ({ name: "", subtitle: "", comment: "", iconPath: "" })
                }

                ListView {
                    id: rows
                    width: parent.width
                    height: Math.min(count, launcher.visibleRows) * launcher.rowHeight
                    visible: count > 0
                    clip: true
                    interactive: count > launcher.visibleRows
                    boundsBehavior: Flickable.StopAtBounds
                    model: launcher.results.slice(1)
                    delegate: ResultRow {}
                    currentIndex: launcher.selectedIndex - 1
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0)
                            positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                }

                Text {
                    visible: launcher.results.length === 0
                    width: parent.width
                    text: AppsState.apps.length === 0 ? "no desktop entries found" : "no matches"
                    color: Theme.colors.fg.muted
                    font.family: Theme.typography.families.mono
                    font.pointSize: Theme.typography.sizes.body
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Text {
                id: status
                anchors.top: body.bottom
                anchors.topMargin: Theme.metrics.space.sm
                anchors.horizontalCenter: parent.horizontalCenter
                height: text.length > 0 ? implicitHeight : 0
                text: AppsState.error
                color: Theme.colors.state.danger
                font.family: Theme.typography.families.mono
                font.pointSize: Theme.typography.sizes.small
            }
        }
    }
}
