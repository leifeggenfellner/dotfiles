import QtQuick

// -- RitualLedger ---------------------------------------------
// LOTM theme plugin. Receives prefs by service injection and
// theme/motion facades by dashboard mount injection.

Rectangle {
    id: root

    property var services: ({})
    property var settings: ({})
    property var theme: ({
            colors: {
                bg: {
                    base: "#1b1510",
                    elevated: "#2a211a",
                    sunken: "#0e0a06",
                    surface1: "#3e3121"
                },
                fg: {
                    primary: "#e6d7b8",
                    muted: "#b5a284",
                    subtle: "#857556"
                },
                accent: {
                    primary: "#c79a3a",
                    secondary: "#6f8da8"
                },
                state: {
                    ok: "#7d9b82"
                }
            },
            metrics: {
                radius: {
                    small: 8,
                    medium: 10
                },
                space: {
                    xs: 4,
                    sm: 8,
                    md: 12,
                    lg: 16
                }
            },
            typography: {
                families: {
                    display: "serif",
                    sans: "sans-serif",
                    mono: "monospace"
                },
                sizes: {
                    small: 10,
                    body: 13,
                    heading: 18
                }
            }
        })
    property var motion: ({
            stateChange: {
                duration: 160,
                easing: Easing.OutCubic
            },
            sealPress: {
                duration: 140,
                easing: Easing.OutCubic
            }
        })

    readonly property var prefs: services.prefs ?? null
    readonly property string namespace: "ritualLedger"
    readonly property string key: Qt.formatDate(new Date(), "yyyy-MM-dd")
    readonly property var entries: settings.entries ?? ["Observe", "Record", "Anchor"]
    readonly property var done: prefs ? prefs.extra(namespace, key, ({})) : ({})
    readonly property int completed: countDone()
    readonly property bool compact: width < 540

    implicitHeight: content.implicitHeight + theme.metrics.space.lg * 2
    height: implicitHeight
    radius: theme.metrics.radius.medium
    color: theme.colors.bg.base
    border.width: 1
    border.color: theme.colors.bg.surface1

    function countDone() {
        let total = 0;
        for (let i = 0; i < entries.length; i++) {
            const id = entryId(entries[i], i);
            if (done[id] === true)
                total++;
        }
        return total;
    }

    function entryId(entry, index) {
        const raw = typeof entry === "string" ? entry : (entry.id ?? entry.label ?? index);
        return String(raw).trim().toLowerCase().replace(/[^a-z0-9]+/g, "-");
    }

    function entryLabel(entry) {
        return typeof entry === "string" ? entry : (entry.label ?? entry.id ?? "ritual");
    }

    function toggle(entry, index) {
        if (!prefs)
            return;
        const id = entryId(entry, index);
        const next = {};
        for (const key in done)
            next[key] = done[key];
        next[id] = next[id] !== true;
        prefs.setExtra(namespace, key, next);
    }

    Column {
        id: content

        anchors.fill: parent
        anchors.margins: root.theme.metrics.space.lg
        spacing: root.theme.metrics.space.md

        Row {
            width: parent.width
            spacing: root.theme.metrics.space.lg
            visible: !root.compact

            Column {
                width: Math.min(220, parent.width * 0.42)
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.metrics.space.xs

                Text {
                    width: parent.width
                    text: root.settings.title ?? "Daily Ritual"
                    color: root.theme.colors.fg.primary
                    font.family: root.theme.typography.families.display
                    font.pointSize: root.theme.typography.sizes.heading
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    text: root.completed + "/" + root.entries.length + " sealed today"
                    color: root.completed === root.entries.length ? root.theme.colors.state.ok : root.theme.colors.fg.subtle
                    font.family: root.theme.typography.families.mono
                    font.pointSize: root.theme.typography.sizes.small
                    wrapMode: Text.WordWrap
                }
            }

            Flow {
                width: parent.width - x
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.theme.metrics.space.sm

                Repeater {
                    model: root.entries

                    RitualChip {}
                }
            }
        }

        Column {
            width: parent.width
            spacing: root.theme.metrics.space.sm
            visible: root.compact

            Text {
                width: parent.width
                text: root.settings.title ?? "Daily Ritual"
                color: root.theme.colors.fg.primary
                font.family: root.theme.typography.families.display
                font.pointSize: root.theme.typography.sizes.heading
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                text: root.completed + "/" + root.entries.length + " sealed today"
                color: root.completed === root.entries.length ? root.theme.colors.state.ok : root.theme.colors.fg.subtle
                font.family: root.theme.typography.families.mono
                font.pointSize: root.theme.typography.sizes.small
                wrapMode: Text.WordWrap
            }

            Flow {
                width: parent.width
                spacing: root.theme.metrics.space.sm

                Repeater {
                    model: root.entries

                    RitualChip {}
                }
            }
        }
    }

    component RitualChip: Rectangle {
        id: chip

        required property var modelData
        required property int index

        readonly property string idKey: root.entryId(modelData, index)
        readonly property bool checked: root.done[idKey] === true

        width: Math.min(116, Math.max(78, label.implicitWidth + root.theme.metrics.space.md * 2))
        height: 38
        radius: root.theme.metrics.radius.small
        color: checked ? root.theme.colors.bg.elevated : root.theme.colors.bg.sunken
        border.width: 1
        border.color: checked ? root.theme.colors.accent.primary : root.theme.colors.bg.surface1
        scale: mouse.pressed ? 0.96 : 1

        Text {
            id: label

            anchors.centerIn: parent
            text: (chip.checked ? "* " : "") + root.entryLabel(chip.modelData)
            color: chip.checked ? root.theme.colors.accent.primary : root.theme.colors.fg.muted
            font.family: root.theme.typography.families.sans
            font.pointSize: root.theme.typography.sizes.small
            elide: Text.ElideRight
            maximumLineCount: 1
            width: parent.width - root.theme.metrics.space.sm * 2
            horizontalAlignment: Text.AlignHCenter
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: root.prefs !== null
            onClicked: root.toggle(chip.modelData, chip.index)
        }

        Behavior on color {
            ColorAnimation {
                duration: root.motion.stateChange.duration
                easing.type: root.motion.stateChange.easing
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: root.motion.stateChange.duration
                easing.type: root.motion.stateChange.easing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.motion.sealPress.duration
                easing.type: root.motion.sealPress.easing
            }
        }
    }
}
