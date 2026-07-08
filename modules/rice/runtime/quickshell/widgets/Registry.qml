pragma Singleton
import QtQuick
import "../core"
import "./workspaces" as Workspaces
import "./clock" as Clock
import "./system" as System
import "./power" as Power
import "./media" as Media
import "./meters" as Meters
import "./epigraph" as Epigraph
import "./divination" as Divination

// ── Registry ──────────────────────────────────────────────────
// The widget registry: built-in descriptors ∪ theme plugins.
// Surfaces render ONLY from this — no hardcoded widget lists (L-001).
// Manifest `widgets.<id>` config overrides placement/settings via
// effective(); Theme.widgetConfig keeps manifest access behind the
// facade.

Item {
    id: registry

    Component {
        id: workspacesGlance
        Workspaces.WorkspacesGlance {}
    }
    Component {
        id: clockGlance
        Clock.ClockGlance {}
    }
    Component {
        id: systemGlance
        System.SystemClusterGlance {}
    }
    Component {
        id: systemPopout
        System.SystemClusterPopout {}
    }
    Component {
        id: powerGlance
        Power.PowerGlance {}
    }
    Component {
        id: powerPopout
        Power.PowerMenuPopout {}
    }
    Component {
        id: mediaGlance
        Media.MediaGlance {}
    }
    Component {
        id: mediaPopout
        Media.MediaPopout {}
    }
    Component {
        id: metersDashboard
        Meters.SystemMetersDashboard {}
    }
    Component {
        id: epigraphDashboard
        Epigraph.EpigraphDashboard {}
    }
    Component {
        id: weatherDashboard
        Divination.WeatherDashboard {}
    }
    Component {
        id: calendarDashboard
        Divination.CalendarDashboard {}
    }

    readonly property list<QtObject> builtins: [
        WidgetDescriptor {
            widgetId: "workspaces"
            region: "left"
            priority: 0
            services: ["hypr"]
            glance: workspacesGlance
        },
        WidgetDescriptor {
            widgetId: "clock"
            region: "center"
            priority: 0
            glance: clockGlance
        },
        WidgetDescriptor {
            widgetId: "system"
            region: "right"
            priority: 0
            services: ["network", "audio", "bluetooth", "power", "tray"]
            glance: systemGlance
            popout: systemPopout
        },
        WidgetDescriptor {
            widgetId: "media"
            region: "right"
            priority: 5
            services: ["mpris"]
            glance: mediaGlance
            popout: mediaPopout
        },
        WidgetDescriptor {
            widgetId: "power"
            region: "right"
            priority: 10
            services: ["session"]
            glance: powerGlance
            popout: powerPopout
        },
        WidgetDescriptor {
            widgetId: "epigraph"
            region: "dashboard"
            priority: 0
            glance: epigraphDashboard
        },
        WidgetDescriptor {
            widgetId: "meters"
            region: "dashboard"
            priority: 10
            services: ["systemStats"]
            glance: metersDashboard
        },
        WidgetDescriptor {
            widgetId: "weather"
            region: "dashboard"
            priority: 20
            services: ["weather"]
            glance: weatherDashboard
        },
        WidgetDescriptor {
            widgetId: "calendar"
            region: "dashboard"
            priority: 30
            services: ["weather"]
            glance: calendarDashboard
        }
    ]

    property var _pluginCache: ({})

    function effectiveById(widgetId) {
        const d = builtins.find(b => b.widgetId === widgetId) ?? _pluginDescriptors().find(p => p.widgetId === widgetId);
        return d ? effective(d) : null;
    }

    function effective(d) {
        const cfg = Theme.widgetConfig(d.widgetId);
        return {
            widgetId: d.widgetId,
            contractVersion: d.contractVersion,
            enabled: cfg.enabled ?? d.enabled,
            region: cfg.region ?? d.region,
            priority: cfg.priority ?? d.priority,
            monitorPolicy: cfg.monitorPolicy ?? d.monitorPolicy,
            services: d.services,
            settings: cfg.settings ?? d.settings,
            glance: d.glance,
            popout: d.popout
        };
    }

    function byRegion(region) {
        return builtins.concat(_pluginDescriptors()).map(effective).filter(w => w.enabled && w.region === region && w.glance !== null).sort((a, b) => a.priority - b.priority);
    }

    function _pluginComponent(plugin) {
        if (!plugin || !plugin.source || plugin.source.length === 0)
            return null;
        const entry = plugin.entry ?? "main.qml";
        const key = plugin.id + "|" + plugin.source + "/" + entry;
        let component = _pluginCache[key];
        if (!component) {
            component = Qt.createComponent("file://" + plugin.source + "/" + entry);
            _pluginCache[key] = component;
        }
        if (component.status === Component.Error) {
            console.warn("Registry: plugin", plugin.id, "failed to load:", component.errorString());
            return null;
        }
        if (component.status !== Component.Ready)
            return null;
        return component;
    }

    function _pluginDescriptors() {
        const out = [];
        const plugins = Theme.plugins;
        for (let i = 0; i < plugins.length; i++) {
            const plugin = plugins[i];
            const component = _pluginComponent(plugin);
            if (!component)
                continue;
            out.push({
                widgetId: plugin.id,
                contractVersion: plugin.contractVersion ?? 1,
                enabled: plugin.enabled ?? true,
                region: plugin.region ?? "dashboard",
                priority: plugin.priority ?? 50,
                monitorPolicy: plugin.monitorPolicy ?? "all",
                services: plugin.services ?? [],
                settings: plugin.settings ?? ({}),
                glance: component,
                popout: null
            });
        }
        return out;
    }
}
