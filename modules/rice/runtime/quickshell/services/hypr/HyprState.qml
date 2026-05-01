pragma Singleton
import QtQuick
import Quickshell.Hyprland

// ── HyprState — REAL (partial) ────────────────────────────────
// Compositor state via Quickshell's native Hyprland binding
// (D-008 tier 1: no polling, no CLI). Deliberately minimal —
// only what surfaces need today. Grows in Phase 5+ (workspaces,
// window title) by porting from the legacy tree.
//
//   state: available, focusedScreenName ("" when unknown)
//
// Focused output is exposed by NAME (matches ShellScreen.name);
// HyprlandMonitor.screen is not reliable on this Quickshell version.

Item {
    id: hypr

    readonly property bool available: Hyprland.focusedMonitor !== null
    readonly property string focusedScreenName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
}
