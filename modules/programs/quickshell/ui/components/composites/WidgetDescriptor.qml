import QtQuick

// ── WidgetDescriptor ─────────────────────────────────────────
// Base contract that every bar widget must satisfy.
// Widgets extend this by placing it as a child of the bar model.
//
// glanceItem:    Component to render in the bar (required).
// popoutContent: Component to render inside PopoutShell (optional).
// enabled:       Hide the widget entirely when false.
// priority:      Compact-mode drop order (lower = drops first).
// monitorPolicy: "all" | "primary" | "byName"

QtObject {
    property string id: ""
    property bool enabled: true
    property int priority: 50
    property string monitorPolicy: "all"

    // Declare as Component {} in subclasses
    property Component glanceItem: null
    property Component popoutContent: null
}
