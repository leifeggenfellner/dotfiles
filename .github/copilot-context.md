# Dotfiles Orchestrator Context

> **NON-AUTHORITATIVE working context.** Law is
> [DECISIONS.md](../docs/architecture/DECISIONS.md),
> [ARCHITECTURE.md](../docs/architecture/ARCHITECTURE.md), and
> [contracts/](../docs/architecture/contracts/). Current code, Git status, and
> explicit user instructions outrank this file. Re-read the nearest authority;
> stale context never overrides it.

## Stable Map

- `flake.nix` + `modules/`: configuration sources. `config/` owns system policy,
  `hardware/` machine constraints, `hosts/` composition, `programs/` application
  behavior, `services/` daemons, and `rice/` desktop framework integration.
- Rice flow: Nix builds validated theme packages/manifests/index -> mutable active
  pointer selects a manifest -> theme-neutral Quickshell runtime reads it ->
  injected services expose system state and commands. See D-003/D-004/D-006.
- Rice runtime DAG: `utils <- core <- components <- widgets <- modules <-
shell.qml`; services depend on utils separately and are injected into
  widgets/modules. Exact rules live in `ARCHITECTURE.md`.
- Generated manifests, derived assets, build output, caches, `result`, lock state,
  secrets, and mutable runtime data are never edited. Change their source owner.
- Never activate Home Manager, deploy, publish, stage, or commit without explicit
  approval. Validation must not load/execute generated Hyprland Lua (D-038).

## Completed DX Refactor Increments

These increments belong only to the DX refactor initiative. Canonical phase
numbering in `ROADMAP.md` remains authoritative and is unrelated.

1. Manifest validation: strict closed-core schema, typed required fields and
   extension points, positive/negative flake check coverage.
2. Theme metrics: workspace/dashboard geometry uses validated typed metrics with
   schema-v2 compatibility defaults and live dashboard repacking.
3. Runtime services: consumption-gated system polling, bounded network restart,
   authoritative/queued brightness operations, pending OSD previews, balanced
   dashboard service references.
4. Workspace UI: reusable service-free `WorkspaceStrip`/`WorkspaceItem` with
   explicit properties/signals; Hyprland commands remain at the widget boundary.
5. Lazy surfaces: bars/event controllers stay eager; heavyweight per-monitor
   surfaces and opted-in dashboard widgets load on demand with conceal/reopen and
   external-theme compatibility safeguards.
6. Hyprland authority ([D-038](../docs/architecture/DECISIONS.md#d-038--hyprland-lua-remains-nix-generated)):
   implemented in the current uncommitted handoff. Home Manager owns the generated
   Lua; NixOS launch policy and Home Manager session state consume the shared
   read-only config path. An approved activation and runtime check remain.
7. Unified theme switching ([D-039](../docs/architecture/DECISIONS.md#d-039--rice-switch-owns-live-hyprland-visual-tokens),
   [D-040](../docs/architecture/DECISIONS.md#d-040--live-theme-switching-is-a-user-transaction)):
   `rice-switch` serializes per-user transactions, pins immutable store index and
   manifests, and coordinates validated Hyprland visuals, exact active-pointer
   replacement, Quickshell reload, and critical wallpaper application. Failure or
   handled interruption compensates attempted effects and reports partial rollback
   when any required restore fails. Wallpaper compensation uses the exact prior
   persisted path, including custom paths outside manifests, and restores exact
   persistence absence when none existed; absent prior visual state is reported as
   partial rollback if wallpaper application may have changed it. The focused check
   runs the packaged wallpaper helper with only `awww` mocked and covers persistence,
   pointer metadata, and TERM status 143. Failed visual compensation prints D-039's
   installed `rice-hyprland-theme --active` recovery command. System specialisations
   remain an explicit separate workflow. The legacy switcher is uninstalled and
   unbound.

## Handoff

- DX refactor increment 8 rollout status (2026-09-10, `shitbox`): preflight and
  `nh os build` completed successfully from clean commit `830be800`; 73
  derivations built and the expected Nix-owned Hyprland config path evaluated.
  The active system remained generation 546. `sudo -n true` reported that a
  password is required, so `nh os switch` was not started and no post-activation
  runtime verification is claimed. No cleaning, reboot, logout, lock, remote
  deployment, source mutation, theme switch, or other live-state mutation ran.
- Next DX refactor increment 8 step: run the approved local `nh os switch` from
  an authenticated terminal, retaining generation 546 as the rollback source,
  then complete startup, lazy-surface, theme transaction, Hyprland mapping,
  wallpaper, multi-monitor, service/hardware, bindings/rules, process, and log
  verification. The pre-activation baseline was unchanged: LOTM resolved via the
  default with no mutable active pointer, persisted/applied wallpaper agreed,
  one rice Quickshell process exposed IPC, and one monitor was present.
- Baseline freshly verified through repaired DX refactor increment 7 on 2026-09-10:
  focused manifest and executable transactional switch checks, explicit
  generated-script ShellCheck, scoped `nixpkgs-fmt --check`, rice lint, no-build
  flake evaluation, both host evaluations, and diff checks passed. No activation,
  live IPC/backend/config, deployment, staging, commit, or runtime-state checks ran.
  The exact stable broad commands are `scripts/rice-lint.sh`,
  `nix flake check path:. --no-build`,
  `nix eval --raw .#nixosConfigurations.shitbox.config.system.build.toplevel.drvPath`,
  `nix eval --raw .#nixosConfigurations.stickytop.config.system.build.toplevel.drvPath`,
  and `git diff --check`; use `path:.#nixosConfigurations...` while relevant files
  remain untracked. Focused checks are `nix build
path:.#checks.x86_64-linux.rice-theme-switch --no-link` and `nix build
path:.#checks.x86_64-linux.rice-manifest-validation --no-link`. Generated files,
  mutable rice state, and live desktop commands were not touched. Historical
  evidence never substitutes for new checks.
- Current worktree caveat (2026-09-10): DX refactor increments 6-7 authority/code and
  user/automation edits are uncommitted. Always re-read `git status`, relevant
  diffs, and untracked files. Never overwrite, revert, normalize, or assume
  ownership of existing work.

## Update Protocol

After a substantive DX refactor increment completes, replace the handoff facts and
append/condense the completed-increment summary. Keep this file small and factual:

```text
Date: YYYY-MM-DD
Completed DX refactor increment: <number/name and high-level outcome>
Changed ownership areas: <stable relative paths or authorities>
Validations: <exact commands and pass/fail; separate historical/runtime checks>
Next DX refactor increment: <number/name and entry condition>
Runtime checks: <performed results, or explicitly not run>
```

Do not store absolute paths, hashes, huge file lists, generated output, secrets,
mutable runtime data, speculative claims, or details recoverable from nearby Law.
