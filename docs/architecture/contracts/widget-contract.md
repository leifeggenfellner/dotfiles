# Contract: Widget

contractVersion: 1.

A widget is a self-describing UI unit rendered into a surface (bar, dock,
dashboard) by the widget registry. Surfaces are pure compositors: they iterate
descriptors, apply region rules, and delegate visuals (L-001). This contract is
the **only** interface plugin widgets may rely on (D-004).

## Descriptor

Every widget exports a descriptor with:

| Field             | Type               | Meaning                                                                               |
| ----------------- | ------------------ | ------------------------------------------------------------------------------------- |
| `id`              | string             | unique, stable; the key used in manifest `widgets.<id>`                               |
| `contractVersion` | int                | version of this contract the widget targets (D-013)                                   |
| `enabled`         | bool               | resolved from manifest config; default true                                           |
| `region`          | string             | surface-defined set: bar uses `left` / `center` / `right`; dashboard uses `dashboard` |
| `priority`        | int                | ordering within a region                                                              |
| `monitorPolicy`   | string             | `all` / `primary` / surface-defined                                                   |
| `services`        | list&lt;string&gt; | service ids this widget needs, e.g. `["audio"]` (D-009)                               |
| `settings`        | object             | widget-defined schema, filled from manifest `widgets.<id>.settings`                   |
| `glanceItem`      | Component          | the always-visible representation                                                     |
| `popoutContent`   | Component?         | optional; rendered inside the shared popout shell                                     |

## Lifecycle & rendering rules

1. The runtime builds a **registry** = built-in widgets ∪ theme plugins (from the
   manifest `plugins` list). Surfaces render only from the registry.
2. **Service injection (D-009):** the mount resolves each id in `services` and
   passes the singleton as a property. Widgets never `import` services. Reads are
   bindings; writes are service command methods only.
3. **Popouts:** at most one popout is open at a time; popouts render inside the
   shared popout shell, anchored to the origin widget, never floating (L-002).
4. **Presentation only:** widgets hold no system state (L-003) and no optimistic
   state; pending/loading UI derives from service `busy`/error flags.
5. **Tokens only:** all colors, spacing, fonts, and motion come from the `Theme`
   and `Motion` facades (L-004, D-010). No manifest access outside `Theme`.
6. Glance items must render acceptably with empty/default settings — a theme that
   configures nothing gets a sane widget.

## Theme customization tiers (in order of preference)

1. **Tokens** — restyle every widget for free.
2. **Settings** — manifest `widgets.<id>.settings` per the widget's own schema
   (e.g. icon set, labels, per-workspace colors for the workspace indicator).
3. **Delegate slots** — a built-in may expose an optional visual delegate property
   a theme can select through settings; the widget's logic is untouched. Delegate
   values are runtime-known names, not arbitrary QML paths. The built-in remains
   responsible for service injection, command dispatch, fallbacks, and empty-state
   behavior. First tier-3 use: `widgets.power.settings.delegate = "radial"`
   selects the ritual-circle power menu while preserving the same SessionState
   actions as the default list.
4. **Plugins** — a genuinely new widget shipped by the theme. Never use a plugin
   to restyle a built-in.

## Plugins

- Declared in the manifest `plugins` list; source lives under
  `modules/rice/themes/<name>/widgets/<Dir>/`.
- A plugin may import runtime `core/`, `components/`, `utils/` and receives its
  declared services by injection — nothing else. It may not import runtime
  `modules/`, `widgets/`, or `services/` internals; those may be refactored freely
  without notice.
- A plugin failing to load disables that widget with a logged warning; it must
  never take down the shell.

## Adding a built-in widget

Touch only: `runtime/quickshell/widgets/<Name>/` (component + descriptor),
the registry entry, and default config. Its settings schema is documented in the
widget's own directory.
