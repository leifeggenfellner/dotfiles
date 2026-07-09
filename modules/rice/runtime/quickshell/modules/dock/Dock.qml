import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../components"
import "../../services/apps"
import "../../services/hypr"

// -- Dock -------------------------------------------------------
// Optional app dock fed by widgets.dock.settings. It resolves
// theme-provided app specs through AppsState and launches through
// the same service path as the launcher.

PanelWindow {
    id: dock

    required property var modelData
    screen: modelData

    readonly property var config: Theme.widgetConfig("dock")
    readonly property var settings: config.settings ?? ({})
    readonly property bool enabledByTheme: settings.enabled === true
    readonly property string monitorPolicy: settings.monitorPolicy ?? config.monitorPolicy ?? "focused"
    readonly property bool onFocusedScreen: !HyprState.available || HyprState.focusedScreenName === dock.screen.name
    readonly property bool open: enabledByTheme && (monitorPolicy !== "focused" || onFocusedScreen) && dockItems.length > 0
    readonly property var configuredItems: settings.apps ?? []
    readonly property int maxItems: settings.maxItems ?? 8
    readonly property int buttonSize: settings.buttonSize ?? 46
    readonly property int appIconSize: Math.max(1, Math.round(buttonSize * 0.62))
    readonly property int fallbackIconSize: Math.max(1, Math.round(buttonSize * 0.54))
    readonly property int bottomMargin: settings.margin ?? Theme.metrics.bar.margin
    readonly property var appCatalog: AppsState.apps
    readonly property var dockItems: resolveItems(appCatalog, configuredItems)

    visible: open || frame.opacity > 0.01

    WlrLayershell.namespace: "rice-dock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors.bottom: true
    margins.bottom: bottomMargin

    exclusiveZone: settings.exclusive === true ? implicitHeight + bottomMargin : 0
    implicitWidth: Math.min(row.implicitWidth + Theme.metrics.space.md * 2, screen.width - Theme.metrics.space.lg * 2)
    implicitHeight: buttonSize + Theme.metrics.space.sm * 2
    color: "transparent"

    function matchFor(spec) {
        if (typeof spec === "string")
            return spec;
        return spec.match ?? spec.id ?? spec.appId ?? spec.name ?? "";
    }

    function labelFor(spec, row) {
        if (typeof spec !== "string" && spec.label && spec.label.length > 0)
            return spec.label;
        return row.name;
    }

    function resolveItems(apps, specs) {
        const available = apps.length;
        const out = [];
        for (let i = 0; i < specs.length && out.length < maxItems; i++) {
            const spec = specs[i];
            const app = AppsState.findApp(matchFor(spec));
            const row = AppsState.rowForApp(app);
            if (!row)
                continue;
            out.push({
                app,
                row,
                label: labelFor(spec, row),
                key: row.id + "|" + out.length + "|" + available
            });
        }
        return out;
    }

    Rectangle {
        id: frame

        anchors.centerIn: parent
        width: row.implicitWidth + Theme.metrics.space.md * 2
        height: parent.height
        radius: height / 2
        color: Theme.colors.bg.base
        opacity: dock.open ? Theme.metrics.bar.opacity : 0
        border.width: 1
        border.color: Theme.colors.bg.surface1

        Behavior on opacity {
            MotionAnim {
                spec: dock.open ? Motion.panelOpen : Motion.panelClose
            }
        }

        Row {
            id: row
            anchors.centerIn: parent
            height: dock.buttonSize
            spacing: Theme.metrics.space.sm

            Repeater {
                model: dock.dockItems

                Rectangle {
                    id: button

                    required property var modelData

                    width: dock.buttonSize
                    height: dock.buttonSize
                    radius: Theme.metrics.radius.medium
                    color: mouse.containsMouse ? Theme.colors.bg.elevated : "transparent"
                    border.width: mouse.containsMouse ? 1 : 0
                    border.color: Theme.colors.accent.primary

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.stateChange.duration
                            easing.type: Motion.stateChange.easing
                        }
                    }

                    Image {
                        visible: button.modelData.row.iconPath.length > 0
                        anchors.centerIn: parent
                        width: dock.appIconSize
                        height: dock.appIconSize
                        source: button.modelData.row.iconPath
                        sourceSize.width: dock.appIconSize * 2
                        sourceSize.height: dock.appIconSize * 2
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    Icon {
                        visible: button.modelData.row.iconPath.length === 0
                        anchors.centerIn: parent
                        name: "settings"
                        size: dock.fallbackIconSize
                        color: mouse.containsMouse ? Theme.colors.accent.primary : Theme.colors.fg.muted
                    }

                    Rectangle {
                        visible: mouse.containsMouse
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.top
                        anchors.bottomMargin: Theme.metrics.space.sm
                        width: Math.min(label.implicitWidth + Theme.metrics.space.sm * 2, 180)
                        height: label.implicitHeight + Theme.metrics.space.xs * 2
                        radius: Theme.metrics.radius.small
                        color: Theme.colors.bg.mantle
                        border.width: 1
                        border.color: Theme.colors.bg.surface1

                        Text {
                            id: label
                            anchors.centerIn: parent
                            width: parent.width - Theme.metrics.space.sm * 2
                            text: button.modelData.label
                            horizontalAlignment: Text.AlignHCenter
                            color: Theme.colors.fg.primary
                            font.family: Theme.typography.families.sans
                            font.pointSize: Theme.typography.sizes.small
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: AppsState.launch(button.modelData.app)
                    }
                }
            }
        }
    }
}
