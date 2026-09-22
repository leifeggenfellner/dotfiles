import QtQuick
import "../../core"
import "../../components"

// Monitor profile status and validated controls.
// Services: monitorControl, hypr (injected).

Column {
    id: root

    property var services: ({})
    property var settings: ({})

    readonly property var monitorControl: services.monitorControl ?? null
    readonly property var hypr: services.hypr ?? null
    readonly property var profileMetadata: ({
            home_office: {
                label: "Home office",
                icon: "monitor"
            },
            work: {
                label: "Work",
                icon: "monitor"
            },
            family_home: {
                label: "Family home",
                icon: "monitor"
            },
            laptop_only: {
                label: "Laptop only",
                icon: "monitor"
            }
        })
    readonly property var profiles: {
        const names = monitorControl?.availableProfiles ?? [];
        if (!Array.isArray(names))
            return [];

        return names.filter(name => typeof name === "string" && name.length > 0).map(name => {
            const metadata = profileMetadata[name] ?? ({});
            return {
                id: name,
                label: metadata.label ?? name.replace(/_/g, " "),
                icon: metadata.icon ?? "monitor"
            };
        });
    }
    readonly property string activeLabel: monitorControl?.activeProfile ? monitorControl.activeProfile.replace(/_/g, " ") : "No active profile"
    readonly property string connectedLabel: {
        const outputs = monitorControl?.connectedOutputs ?? ({});
        const names = Object.keys(outputs).map(key => outputs[key]);
        return names.length > 0 ? names.join(" · ") : "No connected outputs";
    }
    readonly property string warningLabel: {
        const warnings = monitorControl?.warnings ?? [];
        return Array.isArray(warnings) ? warnings.join(" · ") : "";
    }

    width: 340
    spacing: Theme.metrics.space.md

    Connections {
        target: root.hypr
        ignoreUnknownSignals: true
        function onMonitorsRevisionChanged() {
            root.monitorControl?.refresh();
        }
    }

    Component.onCompleted: root.monitorControl?.refresh()

    Item {
        width: parent.width
        height: heading.implicitHeight

        Text {
            id: heading
            text: "Monitor profile"
            color: Theme.colors.fg.primary
            font.family: Theme.typography.families.display
            font.pointSize: Theme.typography.sizes.heading
        }

        Item {
            id: refreshButton
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.typography.sizes.icon + Theme.metrics.space.md
            height: width

            Icon {
                anchors.centerIn: parent
                name: "refresh"
                color: refreshMouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.subtle
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.monitorControl !== null && !root.monitorControl.busy
                onClicked: root.monitorControl.reconcile()
            }

            Rectangle {
                visible: refreshMouse.containsMouse
                anchors.right: parent.right
                anchors.bottom: parent.top
                anchors.bottomMargin: Theme.metrics.space.xs
                width: refreshTip.implicitWidth + Theme.metrics.space.md
                height: refreshTip.implicitHeight + Theme.metrics.space.sm
                radius: Theme.metrics.radius.small
                color: Theme.colors.bg.elevated

                Text {
                    id: refreshTip
                    anchors.centerIn: parent
                    text: "Reconcile"
                    color: Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.small
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: Theme.metrics.space.xs

        Text {
            width: parent.width
            text: root.activeLabel
            color: root.monitorControl?.available ? Theme.colors.accent.primary : Theme.colors.state.warn
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.body
            font.weight: Theme.typography.weights.medium
            font.capitalization: Font.Capitalize
        }

        Text {
            width: parent.width
            text: root.connectedLabel
            color: Theme.colors.fg.subtle
            elide: Text.ElideRight
            font.family: Theme.typography.families.mono
            font.pointSize: Theme.typography.sizes.small
        }

        Text {
            visible: (root.monitorControl?.unknownOutputs.length ?? 0) > 0
            width: parent.width
            text: "Unknown: " + (root.monitorControl?.unknownOutputs.join(" · ") ?? "")
            color: Theme.colors.state.warn
            elide: Text.ElideRight
            font.family: Theme.typography.families.mono
            font.pointSize: Theme.typography.sizes.small
        }

        Text {
            visible: root.warningLabel.length > 0
            width: parent.width
            text: root.warningLabel
            color: Theme.colors.state.warn
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            maximumLineCount: 2
            font.family: Theme.typography.families.sans
            font.pointSize: Theme.typography.sizes.small
        }
    }

    Column {
        width: parent.width
        spacing: Theme.metrics.space.xs

        Repeater {
            model: root.profiles

            Rectangle {
                id: profileRow

                required property var modelData
                readonly property bool selected: root.monitorControl?.mode === "explicit" && root.monitorControl.selectedProfile === modelData.id

                width: parent.width
                height: 34
                radius: Theme.metrics.radius.small
                color: profileMouse.containsMouse || selected ? Theme.colors.bg.elevated : "transparent"
                border.width: selected ? 1 : 0
                border.color: Theme.colors.accent.primary

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    text: profileRow.modelData.label
                    color: profileRow.selected ? Theme.colors.accent.primary : Theme.colors.fg.primary
                    font.family: Theme.typography.families.sans
                    font.pointSize: Theme.typography.sizes.body
                }

                Icon {
                    visible: profileRow.selected
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.metrics.space.sm
                    anchors.verticalCenter: parent.verticalCenter
                    name: profileRow.modelData.icon
                    size: Theme.typography.sizes.small
                    color: Theme.colors.accent.primary
                }

                MouseArea {
                    id: profileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: root.monitorControl !== null && !root.monitorControl.busy
                    onClicked: root.monitorControl.selectProfile(profileRow.modelData.id)
                }
            }
        }

        Rectangle {
            id: autoRow
            readonly property bool selected: root.monitorControl?.mode === "auto"

            width: parent.width
            height: 34
            radius: Theme.metrics.radius.small
            color: autoMouse.containsMouse || selected ? Theme.colors.bg.elevated : "transparent"
            border.width: selected ? 1 : 0
            border.color: Theme.colors.accent.primary

            Text {
                anchors.left: parent.left
                anchors.leftMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                text: "Automatic"
                color: autoRow.selected ? Theme.colors.accent.primary : Theme.colors.fg.primary
                font.family: Theme.typography.families.sans
                font.pointSize: Theme.typography.sizes.body
            }

            Icon {
                visible: autoRow.selected
                anchors.right: parent.right
                anchors.rightMargin: Theme.metrics.space.sm
                anchors.verticalCenter: parent.verticalCenter
                name: "refresh"
                size: Theme.typography.sizes.small
                color: Theme.colors.accent.primary
            }

            MouseArea {
                id: autoMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: root.monitorControl !== null && !root.monitorControl.busy
                onClicked: root.monitorControl.useAuto()
            }
        }
    }

    Text {
        visible: root.monitorControl?.busy ?? false
        width: parent.width
        text: "Reconciling monitors…"
        color: Theme.colors.fg.muted
        font.family: Theme.typography.families.sans
        font.pointSize: Theme.typography.sizes.small
    }

    Text {
        visible: (root.monitorControl?.error.length ?? 0) > 0
        width: parent.width
        text: root.monitorControl?.error ?? ""
        color: Theme.colors.state.danger
        wrapMode: Text.WordWrap
        font.family: Theme.typography.families.sans
        font.pointSize: Theme.typography.sizes.small
    }
}
