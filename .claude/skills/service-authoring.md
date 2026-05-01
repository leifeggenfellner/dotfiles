# Skill: Service Authoring

## Scope

Adding or changing a state singleton under `runtime/quickshell/services/<domain>/`
(audio, network, bluetooth, power, media, compositor, clipboard, weather, prefs…).

## Authority

- **Controls:** service internals — backend choice, state shape, command methods.
- **Reads:** the service contract.
- **May not influence:** UI and presentation (including how state "should" be
  displayed), widget structure, theme data. Services don't know their consumers.

## Rules

- One singleton per domain, named `<Domain>State`, implementing
  [contracts/service-contract.md](../../docs/architecture/contracts/service-contract.md)
  in full. The three most violated rules:
  1. Backend preference order (D-008): Quickshell native service → DBus →
     event-triggered `Process` → timer-polled `Process` (last resort; the
     interval and why no event source exists must be justified in a comment
     at the timer).
  2. Services import only `utils/` — no UI, no `Theme`, no other services.
  3. Consumers never write properties; every mutation is a command method, and
     state updates only when the system confirms the change.
- Expose `available` / `busy` / `error` edge flags; degrade gracefully when the
  backend is missing (no battery, no adapter → `available: false`, no error spam).
- Clean up processes, timers, and connections on reload.
- Persistence goes through `PrefsState` only; no other service touches disk state.
- Document the state shape and command methods in a header comment — that
  comment is the API doc.
- When touching an existing polling service, check ROADMAP's "Ongoing service
  migrations" — prefer migrating it to the native/DBus backend over extending
  the polling code.

## Forbidden

- UI concerns of any kind: styling, popup logic, formatting for display
  (formatting helpers belong in `utils/`).
- Cross-service imports; compose domains in `modules/` or at the widget mount.
- Optimistic state flips before the system confirms.
- Unjustified timers.

## Checklist

- [ ] Best available backend used (or migration noted in ROADMAP).
- [ ] `available`/`busy`/`error` exposed; absent-backend path tested.
- [ ] No UI/theme/service imports; cleanup on reload verified.
- [ ] Header comment documents state + commands.

## Pointers

[service-contract](../../docs/architecture/contracts/service-contract.md) ·
[ROADMAP.md](../../docs/architecture/ROADMAP.md) ·
[DECISIONS.md](../../docs/architecture/DECISIONS.md) (D-008, D-009)
