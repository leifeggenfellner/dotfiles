pragma Singleton
import QtQuick

// Runtime theme object. Reads generated data from ThemeLoader
// and exposes visual constants for the bar.
QtObject {
    id: theme

    // ── Colors (LOTM Catppuccin Mocha base) ──────────────────
    readonly property color base: "#1e1e2e"
    readonly property color mantle: "#181825"
    readonly property color crust: "#11111b"
    readonly property color surface0: "#313244"
    readonly property color surface1: "#45475a"
    readonly property color surface2: "#585b70"
    readonly property color text: "#cdd6f4"
    readonly property color subtext0: "#a6adc8"
    readonly property color subtext1: "#bac2de"
    readonly property color accent: "#fab387"
    readonly property color accentSecondary: "#f9e2af"
    readonly property color accentTertiary: "#74c7ec"

    // ── Typography ───────────────────────────────────────────
    readonly property string fontMono: "JetBrainsMono Nerd Font"
    readonly property string fontDisplay: "Cinzel"
    readonly property int fontSizeBar: 14
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeIcon: 18

    // ── Layout ───────────────────────────────────────────────
    readonly property int barHeight: 40
    readonly property int barMargin: 8
    readonly property int barRadius: 12
    readonly property int barSpacing: 12
    readonly property real barOpacity: 0.85

    // ── Animation ────────────────────────────────────────────
    readonly property int animDuration: 250
    readonly property int animDurationFast: 150

    // ── Pathway sizing ───────────────────────────────────────
    readonly property int pathwayIconSize: 24
    readonly property int pathwaySpacing: 8
}
