# Dashboard v2 Migration Notes

Dashboard v2 keeps the existing descriptor contract working as-is. Existing widgets do not need to declare any new fields.

## Optional Descriptor Fields

- `layout`: object hint for dashboard placement.
  - `colSpan`: requested grid width on the 12-column grid. Defaults to `6`; `epigraph` defaults to `12`.
  - `minHeight`: initial height used before async content reports its measured height.
  - `priority`: dashboard packing priority. Defaults to the descriptor `priority`.
- `unloadWhenClosed`: boolean. When true, the widget Loader remains active during the conceal animation, then unloads after the dashboard is fully hidden.
- `primaryAction`: optional callable. Used as a fallback when Enter/Space activates a focused card and the loaded widget item does not expose `property var primaryAction`.

## Widget Item Additions

Widgets may optionally expose `property var primaryAction` for keyboard activation. Dashboard v2 also injects `surfaceActive` when the widget declares that property, and includes `settings.surfaceActive` for widgets that prefer reading lifecycle state from settings.

## Existing Built-ins

The current dashboard widgets continue to render without changes. Built-in descriptors now include layout hints only to improve first-pass packing before measured heights are available.
