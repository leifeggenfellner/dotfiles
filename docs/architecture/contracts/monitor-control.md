# Contract: Monitor Control

`monitor-control` is the UI-free owner of Hyprland output topology, workspace
placement, and monitor-dependent application routing. Nix is the source of truth
for identities and profiles; the daemon owns runtime status and selection state.

## Identity and profiles

- External monitors match the exact `serial` returned by `hyprctl monitors all -j`.
  Duplicate descriptions are valid; duplicate configured serials are not.
- Connector matching is reserved for a built-in display such as `eDP-1`.
- A profile declares output mode, position, scale, transform, primary preference,
  and ordered workspace assignments. The first workspace on an output receives
  `default:true`.
- Auto detection requires an exact, unique external-serial set. `family_home`
  and `laptop_only` are auto-detectable. `work` and `home_office` require an
  explicit persisted choice because their connected serial sets are identical.
- With an incomplete explicit topology, available declared outputs are applied
  and workspaces not covered by those outputs are assigned to the laptop. With
  an ambiguous or unknown auto topology, existing output state is preserved.

## CLI

The stable command is `monitor-control`:

- `status` prints one JSON object. It includes schema version, daemon availability,
  selection mode, selected and active profiles, connected logical outputs,
  unknown outputs, last fatal error, nonfatal warnings, available profiles, and
  update time.
- `select <profile>` validates and atomically persists an explicit selection,
  then asks the daemon to reconcile.
- `auto` atomically persists automatic mode and reconciles.
- `reconcile` requests reconciliation without changing selection.

Mutating commands use the private
`$XDG_RUNTIME_DIR/monitor-control/control.sock`. Selection is stored at
`$XDG_STATE_HOME/monitor-control/selection.json`; daemon status is atomically
replaced at `$XDG_RUNTIME_DIR/monitor-control/status.json`. QML may consume the
CLI/status but must not write either file or own monitor state.

## Runtime behavior

- The Home Manager user service is part of and wanted by
  `graphical-session.target`. It relies on the Hyprland environment imported into
  the user manager and reconnects to
  `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock`.
- `monitoradded`, `monitoraddedv2`, and `monitorremoved` trigger a deterministic
  trailing-edge reconciliation. Reconnect delay uses bounded event-loop timers;
  there are no hardware polling or shell sleep loops.
- Reconciliation queries `hyprctl monitors all -j`; disabled but connected outputs
  remain in inventory and sparse disabled geometry is always treated as needing
  reconfiguration when a later profile enables the output. The active-only
  `hyprctl monitors -j` result is authoritative for enabled state because this
  compositor build reports `disabled: true` for active outputs in the all-output
  result.
- This compositor build exposes no functional `hyprctl keyword` IPC request.
  Layout, workspace policy, and application routing use `hyprctl eval` with the
  native `hl.monitor`, `hl.workspace_rule`, and `hl.window_rule` APIs. Critical
  geometry and workspace calls run in that order and must succeed before a
  profile is reported active; dynamic app-rule failures remain nonfatal.
- Workspace migration, existing-window routing, and focus restoration use the
  configured compositor package's typed Lua-config dispatcher payloads through
  `hyprctl dispatch`, including `hl.dsp.workspace.move`, `hl.dsp.window.move`,
  and `hl.dsp.focus`. They run only after geometry and workspace policy. These
  dispatches are best-effort: rejection is recorded in `warnings` but does not
  prevent the geometry profile from becoming active.
- Monitor geometry is compared before mutation to avoid unnecessary mode changes
  and flicker. All process calls use fixed argument vectors with no shell.
  Runtime output names are allowlisted, and all values interpolated into `eval`
  expressions use typed Lua literals; no runtime input is accepted as code. No
  legacy topology command is installed alongside `monitor-control`.
- After critical monitor and workspace commands, reconciliation re-queries
  `hyprctl monitors all -j` before reporting a profile active. Every planned
  output must have the requested enabled geometry, while connected configured
  external outputs omitted by the profile must be disabled. A mismatch records
  a fatal error and leaves no active profile published. A failed startup or
  monitor-event reconciliation receives at most two in-process delayed retries;
  a fresh monitor event resets that budget. The fatal status remains visible
  until a retry converges, and persistent failures require a later event or
  explicit `reconcile` request.
