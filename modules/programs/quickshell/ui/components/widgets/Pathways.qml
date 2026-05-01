import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../.."
import "../../services" as Services

Item {
    id: pathways

    property var pathwayData: []
    property int activeWorkspace: 1
    property string pathwaysDir: ""
    readonly property string fallbackPngDir: Services.RepoPaths.lotmPathwaysPngDir

    function isInvalidDir(path) {
        let p = String(path || "");
        return p.trim() === "" || p.indexOf("qs-blackhole") >= 0 || p.startsWith("qrc:");
    }

    function effectiveDir(path) {
        return isInvalidDir(path) ? fallbackPngDir : String(path || "");
    }

    function toFileUrl(path) {
        let p = String(path || "");
        if (p === "")
            return "";
        return p.startsWith("file://") ? p : ("file://" + p);
    }

    Layout.preferredHeight: parent.height
    implicitWidth: row.implicitWidth

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.pathwaySpacing

        Repeater {
            model: pathways.pathwayData

            Item {
                id: pathwayItem
                required property var modelData
                property int wsId: modelData.workspace
                property bool active: String(pathways.activeWorkspace) === String(modelData.workspace)
                property string resolvedDir: pathways.effectiveDir(pathways.pathwaysDir)
                property string iconPath: resolvedDir + "/" + modelData.icon
                property color pathwayColor: modelData.color || Theme.accent
                property bool hovered: false
                property bool hasIconDir: !pathways.isInvalidDir(resolvedDir)

                width: Theme.pathwayIconSize + 16
                height: Theme.pathwayIconSize + 16

                // ── Breathing glow (active, intensity pulses) ────────
                Rectangle {
                    id: glowCircle
                    anchors.centerIn: parent
                    width: Theme.pathwayIconSize * 1.3
                    height: width
                    radius: width / 2
                    color: pathwayItem.pathwayColor
                    opacity: 0

                    SequentialAnimation on opacity {
                        running: pathwayItem.active
                        loops: Animation.Infinite
                        NumberAnimation {
                            from: 0.08
                            to: 0.2
                            duration: 1800
                            easing.type: Easing.InOutSine
                        }
                        NumberAnimation {
                            from: 0.2
                            to: 0.08
                            duration: 1800
                            easing.type: Easing.InOutSine
                        }
                    }

                    // Snap off when inactive
                    states: State {
                        when: !pathwayItem.active
                        PropertyChanges {
                            target: glowCircle
                            opacity: 0
                        }
                    }

                    transitions: Transition {
                        NumberAnimation {
                            property: "opacity"
                            duration: Theme.animDuration
                        }
                    }
                }

                // ── Hover glow (interaction feedback) ───────────────
                Rectangle {
                    anchors.centerIn: parent
                    width: Theme.pathwayIconSize * 1.2
                    height: width
                    radius: width / 2
                    color: pathwayItem.pathwayColor
                    opacity: pathwayItem.hovered && !pathwayItem.active ? 0.1 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animDurationFast
                        }
                    }
                }

                // ── Sparkle particles (active only, subtle) ─────────
                Repeater {
                    model: pathwayItem.active ? 3 : 0

                    Item {
                        id: sparkleWrapper
                        required property int index
                        anchors.centerIn: parent
                        width: 2
                        height: 2

                        property real angle: (index / 3) * 2 * Math.PI
                        property real orbitRadius: Theme.pathwayIconSize * 0.5
                        property real phase: 0

                        NumberAnimation on phase {
                            from: 0
                            to: 2 * Math.PI
                            duration: 3500 + index * 700
                            loops: Animation.Infinite
                        }

                        transform: Translate {
                            x: Math.cos(sparkleWrapper.angle + sparkleWrapper.phase) * sparkleWrapper.orbitRadius
                            y: Math.sin(sparkleWrapper.angle + sparkleWrapper.phase) * sparkleWrapper.orbitRadius
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 2
                            height: 2
                            radius: 1
                            color: pathwayItem.pathwayColor

                            NumberAnimation on opacity {
                                from: 0.7
                                to: 0.15
                                duration: 1200 + sparkleWrapper.index * 300
                                loops: Animation.Infinite
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }

                // ── Pathway image ───────────────────────────────────
                Image {
                    id: pathwayIcon
                    anchors.centerIn: parent
                    width: Theme.pathwayIconSize
                    height: Theme.pathwayIconSize
                    source: pathwayItem.hasIconDir ? pathways.toFileUrl(pathwayItem.iconPath) : ""
                    sourceSize: Qt.size(Theme.pathwayIconSize * 2, Theme.pathwayIconSize * 2)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true

                    opacity: pathwayItem.active ? 1.0 : 0.4
                    scale: pathwayItem.active ? 1.05 : 0.85

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }
                    }
                }

                Text {
                    anchors.centerIn: pathwayIcon
                    visible: !pathwayItem.hasIconDir || pathwayIcon.status !== Image.Ready
                    text: String(pathwayItem.wsId)
                    color: Qt.rgba(pathwayItem.pathwayColor.r, pathwayItem.pathwayColor.g, pathwayItem.pathwayColor.b, pathwayItem.active ? 0.95 : 0.75)
                    opacity: pathwayItem.active ? 1.0 : 0.8
                    font {
                        family: Theme.fontMono
                        pixelSize: 11
                        weight: Font.DemiBold
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: pathwayItem.hovered = true
                    onExited: pathwayItem.hovered = false
                    onClicked: Hyprland.dispatch("workspace " + pathwayItem.wsId)
                }
            }
        }
    }
}
