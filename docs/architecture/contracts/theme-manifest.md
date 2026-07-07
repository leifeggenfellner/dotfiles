# Contract: Theme Manifest

schemaVersion: 2 (v1 = the ad-hoc `theme.json` generated before this contract).

The manifest is the **only** interface between a theme package and the runtime
(D-004, D-006). A theme is a directory under `modules/rice/themes/<name>/` whose
`_theme.nix` evaluates to the attrset below (underscore prefix keeps import-tree
from loading it as a flake-parts module — D-016); `mkThemeManifest`
(`modules/rice/nix/manifest.nix`) validates it and writes JSON into the Nix store.
The runtime reads it exclusively through `core/ManifestLoader.qml`, and exposes it
exclusively through the `Theme` facade.

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
    };
    effects = {                   # OPTIONAL (D-021): ambient atmosphere layers,
      layers = [                  # rendered only while motion.ambient opts in
        # type ∈ "fog" | "particles" | "vignette" (v1 set);
        # tint is a color TOKEN REF ("accent.primary"), never a literal (L-005);
        # opacity/speed/count are clamped to the motion-contract budgets.
        # { type = "fog"; tint = "accent.secondary"; opacity = 0.1; speed = 1.0; band = "bottom"; }
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
      settings = { };             # OPEN: widget-defined settings schema
    };
  };

  plugins = [                     # theme-shipped widgets (widget-contract.md §Plugins)
    { id = "<widgetId>"; source = ./widgets/<Dir>; }
  ];

  integration = {                 # consumed at rebuild by the Nix propagation layer (D-012)
    gtk = { theme; iconTheme; };
    qt = { style; };
    cursor = { name; size; };
    fonts = { packages = [ ]; };
  };
}
```

## Rules

1. **Closed core, open edges (D-005).** Every `tokens.*` key above is guaranteed to
   exist after validation; the runtime may bind to it unconditionally. `palette`,
   `assets.art`, `assets.icons`, and `widgets.<id>.settings` are open-ended and may
   only be read by the widget/plugin they belong to — never by runtime core.
   D-023 clarifies that long-lived built-in surfaces with widget-like settings
   (`launcher`, `dashboard`, `powermenu`, …) use this same id namespace and read
   their data through `Theme.widgetConfig(surfaceId)`.
2. **Assets by role (D-011).** The runtime resolves assets via `Theme.assets`;
   a missing optional role falls back to `modules/rice/shared/` or degrades to
   nothing gracefully. File paths in the manifest are Nix store paths after build.
3. **Fallbacks.** Optional keys default from `shared/` or runtime defaults so a
   minimal theme is ~30 lines: `meta` + `tokens.colors` + one wallpaper.
4. **Validation is a build failure, not a runtime failure.** `mkThemeManifest`
   asserts required keys, color formats, and file existence at eval/build time.
5. **No behavior in the manifest.** The manifest is data. Anything executable
   belongs in a plugin widget under the widget contract.

## Versioning (D-013)

- `schemaVersion` bumps only on breaking changes, each requiring a DECISIONS.md
  entry and a ROADMAP migration note.
- The loader aliases renamed/removed fields for one migration cycle and logs a
  warning; it never crashes on an older supported version.
