pragma Singleton
import QtQuick
import "../core"
import "./workspaces" as Workspaces
import "./clock" as Clock
import "./system" as System
import "./power" as Power
import "./meters" as Meters
import "./epigraph" as Epigraph

// ── Registry ──────────────────────────────────────────────────
// The widget registry: built-in descriptors ∪ (later) theme plugins.
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
        id: metersDashboard
        Meters.SystemMetersDashboard {}
    }
    Component {
        id: epigraphDashboard
        Epigraph.EpigraphDashboard {}
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
        }
    ]

    function effectiveById(widgetId) {
        const d = builtins.find(b => b.widgetId === widgetId);
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
        return builtins
            .map(effective)
            .filter(w => w.enabled && w.region === region && w.glance !== null)
            .sort((a, b) => a.priority - b.priority);
    }
}
