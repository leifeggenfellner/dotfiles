# Contract: Theme Manifest

schemaVersion: 2 (v1 = the ad-hoc `theme.json` generated before this contract).

The manifest is the **only** interface between a theme package and the runtime
(D-004, D-006). A theme package is a directory whose root contains `_theme.nix`
evaluating to the attrset below. Bundled themes live under
`modules/rice/themes/<name>/` (underscore prefix keeps import-tree from loading
them as flake-parts modules — D-016); external packages are supplied through
`rice.themes.<name>.package` (D-035). `mkThemeManifest`
(`modules/rice/nix/manifest.nix`) validates the package and writes JSON into the
Nix store. The runtime reads it exclusively through `core/ManifestLoader.qml`,
and exposes it exclusively through the `Theme` facade.

## Shape

```nix
{
  meta = {
    name = "<slug>";              # required, matches directory name
    displayName = "…";            # required, shown in the switcher
    version = "0.1.0";            # required
    schemaVersion = 2;            # required
    # switcher preview is NOT a manifest field (D-018): ship authored
    # assets/preview.png, or the index build derives a token swatch.
  };

  tokens = {                      # CLOSED schema — every key required unless marked optional
    colors = {
      bg      = { base; mantle; elevated; sunken; surface1; surface2; };
      fg      = { primary; muted; subtle; };
      accent  = { primary; secondary; tertiary; };
      state   = { ok; warn; danger; info; };
    };
    typography = {
      families = { display; sans; mono; };
      # size/weight scale, all ints:
      sizes = { small; body; bar; heading; icon; };
      weights = { regular; medium; bold; };
    };
    metrics = {                   # geometry scale
      radius = { small; medium; large; };
      space  = { xs; sm; md; lg; };
      bar    = { height; margin; spacing; opacity; };
      # OPTIONAL as whole groups in schema-v2 source input for compatibility;
      # normalized manifest JSON always contains every field shown here.
      workspaces = { slotSize; ringExpansion; iconSize; iconSourceSize; };
      dashboard = {
        columnCount; compactBreakpoint; sidebarRatio;
        sidebarMinWidth; sidebarMaxWidth; mainMinWidth;
        epigraphMinHeight; defaultMinHeight;
      };
    };
    motion = {                    # see contracts/motion-contract.md
      durations = { fast; base; slow; overlay; };
      # OPTIONAL (D-022): infrequent, deliberate moments; defaults to slow.
      # durations.ceremonial = 700;
      easings   = { standard; enter; exit; emphasis; };   # named curve specs
      # Curve names are Qt easing names ("OutCubic", "InOutBack", …),
      # resolved by the runtime; unknown names warn and fall back (D-022).
      intensity = "calm" | "lively";                       # global scaler hint
      ambient   = false;          # opt-in to the ambient effect tier
      enabled   = true;           # theme-level motion kill switch
      compositor = {              # OPTIONAL (D-047): Hyprland window motion styles;
        windowsIn  = "popin 85%"; #   timings derive from durations/easings above.
        windowsOut = "popin 92%"; #   slide | gnomed | popin N%
        workspaces = "slidefadevert 15%"; # slide | slidevert | fade | slidefade[vert] N%
        layers     = "fade";      #   slide | fade | popin N%
        borderSweep = "once";     #   (D-049) gradient turns once on focus; never loops
        borderFade = "off";       #   (D-073) border colour snaps on focus instead of fading
      };
    };
    chrome = {                    # OPTIONAL (D-049): Hyprland window chrome; colour TOKEN REFS (L-005)
      border = { active = [ "state.warn" "accent.primary" ]; angle = 45; };  # 1-4 stops, angle 0..359
      groupbar = {                # every key optional
        active = [ "accent.primary" ]; inactive = [ "bg.elevated" ];       # 1-4 stops, drawn at 90°
        text = "bg.sunken"; textInactive = "fg.muted";
        font = "display";         # display | sans | mono → tokens.typography.families
      };
    };
    effects = {                   # OPTIONAL (D-021): ambient atmosphere layers,
      layers = [                  # rendered only while motion.ambient opts in
        # type ∈ "fog" | "particles" | "vignette" | "rain" (rain: D-046);
        # tint is a color TOKEN REF ("accent.primary"), never a literal (L-005);
        # opacity/speed/count are clamped to the motion-contract budgets.
        # Shader-capable layer types use runtime-owned shaders when compiled
        # (D-028); themes never ship shader source or bytecode.
        # { type = "fog"; tint = "accent.secondary"; opacity = 0.1; speed = 1.0; band = "bottom"; }
      ];
      presets = [                 # OPTIONAL (D-046): applied while a sky condition holds
        # when ∈ "fullMoon" | "rain" | "fog"; window = days around full (fullMoon);
        # tints = { <layer type> = token ref; }; strength = { <layer type> = gain; };
        # layers = [ extra layers, same schema; still within the 4-layer budget ];
        # { when = "fullMoon"; window = 1.5; tints.vignette = "accent.tertiary"; }
      ];
    };
  };

  palette = { };                  # OPEN, optional: extra named colors, namespaced by the
                                  # theme (e.g. palette.<name>.workspaceGlyphs.…). The
                                  # runtime never reads specific keys here; only theme
                                  # plugins and widget settings may reference them.

  assets = {                      # role → path. Roles below are known to the runtime;
    # wallpapers is NOT declared here (D-019): assets/wallpapers/ is
    # globbed at build (png/jpg/jpeg/webp, sorted) into
    # assets.wallpapers as store paths; may be empty; never hand-listed.
    # Likewise assets/lockscreen/ → assets.lockscreen (D-020, optional):
    # the lock-screen script uses entry [0] as the lock background,
    # falling back to the live wallpaper when absent.
    lockscreenVariant = "default"; # optional, D-037: "default" | "lotm".
                    # Selects the theme's canonical rice-lock-screen
                    # root; CLI/env overrides still win.
    logo = null;                  # optional
    launcherIcon = null;          # optional
    icons = { };                  # optional: semantic icon-name overrides (D-016).
                                  # value with "/" = file relative to assets root;
                                  # anything else = font glyph
    sounds = { };                 # optional: semantic event-name → file relative to
                                  # assets root, resolved by Theme.soundUrl (D-024)
    art = { };                    # OPEN, optional: namespaced artwork used via settings/plugins
  };

  widgets = {                     # per built-in widget/surface id (D-023; see widget-contract.md)
    "<widgetId>" = {
      enabled = true;
      region = "left" | "center" | "right";
      priority = 0;
      monitorPolicy = "all" | "primary" | "…";
      unloadWhenClosed = false;    # optional; see widget lifecycle contract
      settings = { };             # OPEN: widget-defined settings schema
    };
  };

  plugins = [                     # theme-shipped widgets (widget-contract.md §Plugins)
    {
      id = "<widgetId>";
      source = "widgets/<Dir>";   # theme-relative plugin directory
      entry = "main.qml";         # optional, defaults to main.qml
      region = "dashboard";
      priority = 50;
      services = [ ];
      unloadWhenClosed = false;   # optional; see widget lifecycle contract
    }
  ];

  integration = {                 # consumed at rebuild by the Nix propagation layer (D-012)
    gtk = { theme; iconTheme; };
    qt = { style; };
    cursor = {                    # optional (D-048); applied live by rice-hyprland-theme
      name = "<icon-theme-name>"; # [A-Za-z0-9._-]+
      size = 24;                  # 8..128
      shapes = {                  # optional: build the cursor from theme SVGs
        default = { svg = ./assets/cursor/<file>.svg; hotspot = [ 0.06 0.06 ]; };
        # required: default pointer text wait ns-resize ew-resize move;
        # optional: progress nwse-resize nesw-resize crosshair not-allowed
      };
    };
    fonts = { packages = [ ]; };
    tools = [ "btop" "bat" "yazi" "cava" ];  # optional (D-051): token-derived tool themes at rebuild
    boot = {                      # optional (D-044); never copied into manifest JSON
      sigil = ./assets/<file>.svg;   # required: single-colour SVG, recoloured to accent.primary
      promptLabel = "<copy>";        # optional: shown above the real passphrase prompt
      font = ./<file>.ttf;           # optional: Plymouth prompt font
    };
  };
}
```

## Rules

1. **Closed core, open edges (D-005).** Every `tokens.*` key above is guaranteed to
   exist in normalized manifest JSON; the runtime may bind to it unconditionally.
   Schema-v2 source input must provide the full Phase 1 core. The later-added
   `tokens.metrics.workspaces` and `tokens.metrics.dashboard` groups may each be
   omitted as a whole for D-013 compatibility and are filled with the defaults
   below. If either group is present, all of its fields are required. `palette`,
   `assets.art`, `assets.icons`, and `widgets.<id>.settings` are open-ended and may
   only be read by the widget/plugin they belong to — never by runtime core.
   D-023 clarifies that long-lived built-in surfaces with widget-like settings
   (`launcher`, `dashboard`, `powermenu`, …) use this same id namespace and read
   their data through `Theme.widgetConfig(surfaceId)`. D-042 adds the
   out-of-shell `terminal` id (read by `rice-terminal`), whose settings may name
   other manifest paths by theme-authored dotted path. D-046 adds `skyLines`
   (epigraph) and `skyLabels` (calendar) keyed by sky condition. D-045 adds the `mood` id
   (read by `modules/mood/MoodController`): `workspaces.<name>` gives a named
   workspace an effects list, backdrop, title, DND, and entry sound. D-053 adds
   the `awakening` id (read by `modules/awakening/AwakeningController`):
   `{ title; subtitle?; hold?; lift?; sound?; }` opts the theme into the
   once-per-login fog-lift. D-054 adds the `dailyAccent` id (read by
   `modules/dailyAccent/DailyAccentController`, `rice-query`, `rice-terminal`,
   the fastfetch card and the Hyprland adapter): `{ record; catalog; }`, where
   `record` is `extras.<ns>.<key>` and catalog entries may carry `accent`
   (`#rrggbb`, replacing `accent.primary` on their day) and `sigil` (an
   assets-relative `.svg`). D-063 adds the `bar` id (read by
   `modules/bar/TopBar`): `{ style; frame?; caps?; glow?; }` picks the
   floating or rail frame, its nine-sliced pieces (`body`, `plaque`, and
   from D-070 `popout`, the hinged popout plate), its end caps, and from
   D-071 `inset` (room inside the rail's border) and `plaquePad` (room
   inside each plaque); and
   `widgets.clock.settings.layout` (`stacked` | `inline`). D-064 adds
   settings for `system`, `media`, `monitor-profile` and the opt-in
   `tray` hatch, and the icon names `wifi-0`…`wifi-3`, `battery-ink` and
   `battery-ink-low`, used when the theme names them. D-065 adds
   `widgets.workspaces.settings.bezel`. D-067 adds
   `widgets.workspaces.settings.carousel = { card?; nameplate?; copy?; }`
   (read by `modules/workspaceCarousel`): nine-sliced card and nameplate
   pieces, and the window-count copy `{ none; one; many }` with `{n}`.
   D-068 adds `carousel.capture = { tint?; strength?; }`, which turns on
   window captures on the cards. D-076 adds the `plates` id
   (read by `components/PlateFrame`): `{ panel?; toast?; }`, each a
   nine-sliced `{ src; slice; }` under assets/. `panel` sits behind the
   launcher, dashboard and notification centre, `toast` behind toasts
   (not letters); a surface keeps its rounded fill without one. D-074 adds the `ornaments` id (read by
   `modules/windowOrnaments`): `{ corner; size?; reach?; inactive?; }`
   draws `corner` (an `.svg` under assets/, the top-left piece, mirrored
   for the others) at each window frame's corners; `size` is 16..96 px
   (default 48), `reach` how far the frame's outer corner sits from the
   art's top-left (0..size/2, default 6), and `inactive` its opacity on
   unfocused windows (0..1, default 0.55).
2. **Assets by role (D-011).** The runtime resolves assets via `Theme.assets`;
   a missing optional role falls back to `modules/rice/shared/` or degrades to
   nothing gracefully. File paths in the manifest are Nix store paths after build.
3. **Fallbacks and source compatibility.** A minimal schema-v2 source still contains
   `meta` and the full required Phase 1 token schema (`colors`, `typography`,
   `metrics.radius`, `metrics.space`, `metrics.bar`, and `motion`). It may omit the
   two later metric groups above. `mkThemeManifest` normalizes omissions to the
   previous runtime literals: `workspaces = { slotSize = 30; ringExpansion = 4;
iconSize = 24; iconSourceSize = 48; }` and `dashboard = { columnCount = 12;
compactBreakpoint = 1120; sidebarRatio = 0.46; sidebarMinWidth = 360;
sidebarMaxWidth = 560; mainMinWidth = 440; epigraphMinHeight = 112;
defaultMinHeight = 180; }`. Optional assets and open-edge data continue to
   default from `shared/` or runtime defaults. Runtime defaults preserve
   no-manifest development and compatibility with previously built schema-v2 JSON.
4. **Validation is a build failure, not a runtime failure.** `mkThemeManifest`
   asserts required keys, color formats, and file existence at eval/build time.
5. **No behavior in the manifest.** The manifest is data. Anything executable
   belongs in a plugin widget under the widget contract.
   Shader programs are the D-028 exception in the other direction: they are
   runtime-owned assets selected only by manifest data, never theme-provided code.
6. **Plugin packaging (D-027, D-035).** The manifest builder validates
   theme-relative plugin source directories and entry files at build time, then
   serializes the containing theme package root as a Nix store path plus a
   theme-root-relative entry path. Keep plugin-local assets under the plugin
   directory and resolve them from QML with relative URLs.

## Hyprland visual mapping (D-039, amended by D-047, D-048, D-049)

The live Hyprland adapter (`rice-hyprland-theme`) consumes the normalized manifest
and applies one Lua chunk through `hyprctl eval`. The complete mapping is
`tokens.colors.accent.primary` to active general/group borders,
`tokens.colors.bg.elevated` to inactive general/group borders,
`animations.enabled` (off under the reduce-motion pref or
`tokens.motion.enabled = false`), and, when present, `tokens.motion.compositor`
window/workspace/layer styles with speeds and curves derived from
`tokens.motion.durations` and `tokens.motion.easings` (the border sweep plays
`borderangle` once over two `slow` durations). `tokens.chrome` (D-049) turns the
active border into a gradient and sets group-bar colours, text colours and
font; every apply first restores the group-bar baseline from
`programs/hyprland/_chrome.nix`, so a theme without it shows the generated
config's group bar. D-072 adds `border.inactive` (a gradient), `border.width`
(1..8), `rounding` (0..32) and `shadow = { color?; range?; power?; offset?; }`;
every apply first restores the generated config's border width, rounding and
shadow, so a theme without them keeps that shape. Gaps are not mapped; they
stay with the generated Hyprland config. After the Lua chunk the
adapter runs `hyprctl setcursor` with `integration.cursor` (D-048), or the base
style's cursor for a theme without one; a theme cursor that is not installed in
an icon directory fails the adapter before any IPC. Adding another live
Hyprland value requires extending this explicit contract and its adapter tests.
Binds, rules, input, and other behavioral settings are never manifest-controlled.

## Versioning (D-013)

- `schemaVersion` bumps only on breaking changes, each requiring a DECISIONS.md
  entry and a ROADMAP migration note.
- The loader aliases renamed/removed fields for one migration cycle and logs a
  warning; it never crashes on an older supported version.
