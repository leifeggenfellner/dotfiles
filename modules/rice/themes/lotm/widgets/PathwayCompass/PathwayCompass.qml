import QtQuick

// -- PathwayCompass -------------------------------------------
// LOTM theme plugin. It is data-only and reads pathway rows from
// manifest settings through the injected settings object.

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
                    secondary: "#6f8da8",
                    tertiary: "#7d9b82"
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
            }
        })

    readonly property var pathways: settings.pathways ?? [
        {
            name: "Fool",
            sequence: "9",
            state: "acting",
            color: theme.colors.accent.primary
        },
        {
            name: "Door",
            sequence: "8",
            state: "listening",
            color: theme.colors.accent.secondary
        },
        {
            name: "Visionary",
            sequence: "7",
            state: "recording",
            color: theme.colors.accent.tertiary
        }
    ]
    readonly property int activeIndex: Math.max(0, Math.min(pathways.length - 1, settings.activeIndex ?? 0))
    readonly property var activePathway: pathways.length > 0 ? pathways[activeIndex] : ({})

    width: 672
    height: 112
    radius: theme.metrics.radius.medium
    color: theme.colors.bg.base
    border.width: 1
    border.color: theme.colors.bg.surface1

    function pathwayColor(row, fallback) {
        return row && row.color ? row.color : fallback;
    }

    Row {
        anchors.fill: parent
        anchors.margins: root.theme.metrics.space.lg
        spacing: root.theme.metrics.space.lg

        Column {
            width: 180
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.metrics.space.xs

            Text {
                width: parent.width
                text: root.settings.title ?? "Pathway Compass"
                color: root.theme.colors.fg.primary
                font.family: root.theme.typography.families.display
                font.pointSize: root.theme.typography.sizes.heading
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: (root.activePathway.name ?? "unknown") + " sequence " + (root.activePathway.sequence ?? "?")
                color: root.theme.colors.fg.subtle
                font.family: root.theme.typography.families.mono
                font.pointSize: root.theme.typography.sizes.small
                elide: Text.ElideRight
            }
        }

        Row {
            width: parent.width - 180 - parent.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.theme.metrics.space.sm

            Repeater {
                model: root.pathways

                Rectangle {
                    id: card

                    required property var modelData
                    required property int index

                    readonly property bool active: index === root.activeIndex
                    readonly property color accent: root.pathwayColor(modelData, root.theme.colors.accent.primary)

                    width: (parent.width - root.theme.metrics.space.sm * Math.max(0, root.pathways.length - 1)) / Math.max(1, root.pathways.length)
                    height: 68
                    radius: root.theme.metrics.radius.small
                    color: active ? root.theme.colors.bg.elevated : root.theme.colors.bg.sunken
                    border.width: active ? 2 : 1
                    border.color: active ? accent : root.theme.colors.bg.surface1

                    Row {
                        anchors.fill: parent
                        anchors.margins: root.theme.metrics.space.sm
                        spacing: root.theme.metrics.space.sm

                        Rectangle {
                            width: 8
                            height: parent.height
                            radius: 4
                            color: card.accent
                            opacity: card.active ? 1 : 0.52
                        }

                        Column {
                            width: parent.width - 8 - parent.spacing
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                width: parent.width
                                text: card.modelData.name ?? "Pathway"
                                color: root.theme.colors.fg.primary
                                font.family: root.theme.typography.families.sans
                                font.pointSize: root.theme.typography.sizes.body
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "Seq. " + (card.modelData.sequence ?? "?") + " / " + (card.modelData.state ?? "quiet")
                                color: card.active ? card.accent : root.theme.colors.fg.subtle
                                font.family: root.theme.typography.families.mono
                                font.pointSize: root.theme.typography.sizes.small
                                elide: Text.ElideRight
                            }
                        }
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
                }
            }
        }
    }
}
