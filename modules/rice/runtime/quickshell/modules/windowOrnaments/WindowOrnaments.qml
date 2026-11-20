pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../core"
import "../../services/hypr"

// ── WindowOrnaments ───────────────────────────────────────────
// Corner ornaments over the window frames of one screen (D-074). The
// theme's `corner` art is the top-left piece; it is mirrored for the
// other three. `reach` is how far the frame's outer corner sits from
// the art's top-left, so the art can reach out into the gap and in
// over the window. Unfocused windows draw it at `inactive` opacity.
//
// Corners covered by a floating window above are skipped, and nothing
// is drawn while the workspace has a fullscreen window. The surface
// takes no input and no keyboard focus. While windows settle
// (ShellState.windowsSettling) the ornaments fade out and return on
// Motion.fade, which survives reduce-motion.

PanelWindow {
    id: overlay

    required property var modelData
    screen: modelData

    readonly property var settings: Theme.widgetConfig("ornaments").settings ?? ({})
    readonly property int size: settings.size ?? 48
    readonly property int reach: settings.reach ?? 6
    readonly property real inactive: settings.inactive ?? 0.55
    readonly property int border: Theme.frameWidth

    readonly property var corners: {
        const all = HyprState.windowFrames(overlay.screen.name);
        if (all.some(w => w.fullscreen))
            return [];
        const b = border;
        const out = [];
        for (const w of all) {
            // Floating windows sit above tiled ones; among floating,
            // the more recently focused is on top.
            const covers = (px, py) => all.some(o => o !== w && o.floating && (!w.floating || o.stack < w.stack)
                && px >= o.x - b && px <= o.x + o.width + b && py >= o.y - b && py <= o.y + o.height + b);
            for (const [cx, cy] of [[0, 0], [1, 0], [0, 1], [1, 1]]) {
                const px = w.x - b + cx * (w.width + 2 * b);
                const py = w.y - b + cy * (w.height + 2 * b);
                if (!covers(px, py))
                    out.push({ px: px, py: py, fx: cx ? -1 : 1, fy: cy ? -1 : 1, focused: w.focused });
            }
        }
        return out;
    }

    WlrLayershell.namespace: "rice-ornaments"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    mask: Region {}

    Item {
        anchors.fill: parent
        opacity: ShellState.windowsSettling ? 0 : 1

        Behavior on opacity {
            MotionAnim {
                spec: ShellState.windowsSettling ? Motion.panelClose : Motion.fade
            }
        }

        Repeater {
            model: overlay.corners

            delegate: Image {
                required property var modelData

                x: modelData.px - (modelData.fx > 0 ? overlay.reach : overlay.size - overlay.reach)
                y: modelData.py - (modelData.fy > 0 ? overlay.reach : overlay.size - overlay.reach)
                width: overlay.size
                height: overlay.size
                source: Theme.assetUrl(overlay.settings.corner)
                sourceSize.width: overlay.size * 2
                sourceSize.height: overlay.size * 2
                smooth: true
                opacity: modelData.focused ? 1 : overlay.inactive
                transform: Scale {
                    origin.x: overlay.size / 2
                    origin.y: overlay.size / 2
                    xScale: modelData.fx
                    yScale: modelData.fy
                }
            }
        }
    }
}
