import QtQuick

// ── WidgetDescriptor ──────────────────────────────────────────
// The widget contract (contracts/widget-contract.md): every widget
// registers one of these. Manifest `widgets.<widgetId>` overrides
// enabled/region/priority/monitorPolicy/settings at resolve time
// (see Registry.effective).

QtObject {
    property string widgetId: ""
    property int contractVersion: 1
    property bool enabled: true
    property string region: "right"
    property int priority: 0
    property string monitorPolicy: "all"
    property var services: []
    property var settings: ({})
    property var layout: ({})
    property bool unloadWhenClosed: false
    property var primaryAction: null
    property Component glance: null
    property Component popout: null
}
