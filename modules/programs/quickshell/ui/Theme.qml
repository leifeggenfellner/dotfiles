pragma Singleton
import QtQuick
import "./services" as Services

QtObject {
    id: theme

    // ── Convenience alias ─────────────────────────────────────
    readonly property var t: Services.ThemeLoader.tokens

    // ── Colors ───────────────────────────────────────────────
    readonly property color base: t.bg.base
    readonly property color mantle: t.bg.mantle
    readonly property color crust: t.bg.sunken
    readonly property color surface0: t.bg.elevated
    readonly property color surface1: t.bg.surface1
    readonly property color surface2: t.bg.surface2
    readonly property color text: t.fg.primary
    readonly property color subtext0: t.fg.muted
    readonly property color subtext1: t.fg.subtle
    readonly property color accent: t.accent.primary
    readonly property color accentSecondary: t.accent.secondary
    readonly property color accentTertiary: t.accent.tertiary

    // ── State colors ─────────────────────────────────────────
    readonly property color stateOk: t.state.ok
    readonly property color stateWarn: t.state.warn
    readonly property color stateDanger: t.state.danger

    // ── Typography ───────────────────────────────────────────
    readonly property string fontDisplay: t.font.display
    readonly property string fontMono: t.font.mono
    readonly property string fontSans: t.font.sans
    readonly property int fontSizeBar: t.font.sizeBar
    readonly property int fontSizeSmall: t.font.sizeSmall
    readonly property int fontSizeIcon: t.font.sizeIcon

    // ── Layout ───────────────────────────────────────────────
    readonly property int barHeight: t.bar.height
    readonly property int barMargin: t.bar.margin
    readonly property int barRadius: t.bar.radius
    readonly property int barSpacing: t.bar.spacing
    readonly property real barOpacity: t.bar.opacity

    readonly property int chipRadius: t.radius.chip
    readonly property int sigilRadius: t.radius.sigil
    readonly property int popoutRadius: t.radius.popout

    // ── Spacing ───────────────────────────────────────────────
    readonly property int spaceXs: t.space.xs
    readonly property int spaceSm: t.space.sm
    readonly property int spaceMd: t.space.md
    readonly property int spaceLg: t.space.lg

    // ── Animation ────────────────────────────────────────────
    readonly property int animDurationFast: t.dur.fast
    readonly property int animDuration: t.dur.base
    readonly property int animDurationSlow: t.dur.slow
    readonly property int animDurationOverlay: t.dur.overlay
    readonly property bool motionEnabled: t.motionEnabled

    // ── Overlay layout (unchanged) ────────────────────────────
    readonly property int overlayLaneGap: 12
    readonly property int overlayEdgePad: 8
    readonly property int overlayZTooltip: 200
    readonly property int overlayZCommand: 220

    // ── Pathway sizing (unchanged) ────────────────────────────
    readonly property int pathwayIconSize: 30
    readonly property int pathwaySpacing: 4
}
