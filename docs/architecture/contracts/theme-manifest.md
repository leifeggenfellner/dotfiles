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
    preview = ./preview.png;      # required, used by the rice switcher
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
      easings   = { standard; enter; exit; emphasis; };   # named curve specs
      intensity = "calm" | "lively";                       # global scaler hint
      ambient   = false;          # opt-in to the ambient effect tier
      enabled   = true;           # theme-level motion kill switch
    };
    sound = { };                  # OPTIONAL: event name → file path (see motion-contract)
  };

  palette = { };                  # OPEN, optional: extra named colors, namespaced by the
                                  # theme (e.g. palette.<name>.workspaceGlyphs.…). The
                                  # runtime never reads specific keys here; only theme
                                  # plugins and widget settings may reference them.

  assets = {                      # role → path. Roles below are known to the runtime;
    wallpapers = [ ];             # required, ≥1 entry
    logo = null;                  # optional
    launcherIcon = null;          # optional
    icons = { };                  # optional: semantic icon-name overrides (D-016).
                                  # value with "/" = file relative to assets root;
                                  # anything else = font glyph
    art = { };                    # OPEN, optional: namespaced artwork used via settings/plugins
  };

  widgets = {                     # per built-in widget id (see widget-contract.md)
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
