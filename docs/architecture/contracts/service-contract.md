# Contract: Service

A service is a UI-free singleton owning one domain of system state
(audio, network, bluetooth, power, media, compositor, clipboard, weather, prefs…).
Services are the only place system state lives (L-003).

## A service MUST

1. Be a singleton named `<Domain>State` under
   `runtime/quickshell/services/<domain>/`.
2. Expose **typed reactive state** (readonly properties from the consumer's
   perspective) plus **command methods** for every mutation
   (`setVolume(v)`, `connect(id)`, …). Consumers never write properties.
3. Expose edge-state flags where relevant: `available` (backend present),
   `busy` (command in flight), `error` (last failure, clearable). UI derives
   loading/error visuals from these — never from optimistic local state.
4. Reflect **real** system state: after a command, the property updates when the
   system reports the change, not when the command is sent.
5. Prefer backends in this order (D-008):
   1. Quickshell native services (Pipewire, Mpris, UPower, Notifications,
      SystemTray, Hyprland IPC),
   2. DBus (NetworkManager, BlueZ, logind, portals),
   3. event-triggered `Process` calls,
   4. timer-polled `Process` calls — last resort; the interval and the reason no
      event source exists must be justified in a comment at the timer.
6. Clean up processes, timers, and connections on reload/unmount.
7. Degrade gracefully when its backend is absent (no battery, no bluetooth
   adapter): `available: false`, no errors spammed, dependent widgets hide.

## A service MUST NOT

- Import anything from `core/`, `components/`, `widgets/`, or `modules/` — no UI,
  no `Theme`, no `Motion`. Services do not style and do not know who consumes them.
- Import other services. Cross-domain composition happens in `modules/` or in the
  consuming widget's mount, not by chaining singletons.
- Hold UI state (open popouts, hover, selection) — that belongs to `ShellState`.
- Persist state itself; persistence goes through `PrefsState`
  (`$XDG_STATE_HOME/rice/`), the only service that touches disk state.

## Consumption

- Widgets declare service ids in their descriptor and receive the singletons by
  injection (D-009, widget-contract.md).
- Surface modules (`modules/`) may import services directly.
- OSD-style consumers subscribe to change *signals* carrying a user-initiated
  hint, so initial boot-time reads do not trigger popups.

## Adding a service

Touch only `runtime/quickshell/services/<domain>/`. Register nothing globally —
singletons are discovered via the folder's `qmldir`. Document the state shape and
commands in a header comment; that comment is the service's API doc.
