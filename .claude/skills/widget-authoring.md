# Skill: Widget Authoring

## Scope

Adding or changing a widget — built-in (`runtime/quickshell/widgets/<Name>/`) or
theme plugin (`themes/<name>/widgets/<Dir>/`).

## Authority

- **Controls:** widget internals — descriptor implementation, glance/popout
  composition, the widget's own settings schema.
- **Reads:** widget and motion contracts, Theme/Motion facades, the state shapes
  services expose.
- **May not influence:** service backends or behavior (a widget needing new
  service state is a service-contract request, not a widget matter), runtime
  layering rules, the manifest schema.

## Rules

- Implement the descriptor exactly as specified in
  [contracts/widget-contract.md](../../docs/architecture/contracts/widget-contract.md):
  `id`, `contractVersion`, `enabled`, `region`, `priority`, `monitorPolicy`,
  `services`, `settings`, `glanceItem`, optional `popoutContent`.
- Services arrive by injection from the declared `services` list (D-009) —
  never imported. Read via bindings; mutate via service command methods only.
- Split glance vs popout: the glance item is cheap and always-on; popout content
  loads lazily inside the shared popout shell (single popout, anchored — L-002).
- All styling from `Theme.*`, all animation from `Motion.*`. If a needed token
  or semantic animation doesn't exist, add it there — don't inline values.
- Define the `settings` schema in the widget's directory and make every setting
  optional: the widget must render sanely with empty settings.
- No system state in the widget (L-003); pending/error UI derives from service
  `busy`/`error` flags — no optimistic state.
- Surfaces render from the registry; a new built-in is added by creating its
  directory + registry entry, never by editing surface compositors.

## Forbidden

- `import`ing services or reading manifest JSON directly.
- Plugins importing runtime `modules/`, `widgets/`, or `services/` internals.
- A plugin that restyles a built-in (use tokens/settings/delegate slots).
- Timers or polling inside widgets — that's a service concern.

## Checklist

- [ ] Descriptor complete, `id` stable, `contractVersion` set.
- [ ] Renders with empty settings and with services unavailable.
- [ ] No hardcoded style/motion values; no direct service imports.
- [ ] Popout (if any) is lazy, anchored, and closes via ShellState.

## Pointers

[widget-contract](../../docs/architecture/contracts/widget-contract.md) ·
[motion-contract](../../docs/architecture/contracts/motion-contract.md) ·
[service-contract](../../docs/architecture/contracts/service-contract.md)
