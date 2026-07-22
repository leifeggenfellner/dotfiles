# Checkpoint: Runtime-Neutral Lock Entrypoints

## Summary

Normalized the Quickshell runtime lock entrypoint filenames to be theme-neutral,
while preserving `--variant lotm` behavior in `rice-lock-screen`.

## What Changed

- Renamed runtime entry roots:
  - `modules/rice/runtime/quickshell/lock-lotm.qml` -> `modules/rice/runtime/quickshell/lock-theme.qml`
  - `modules/rice/runtime/quickshell/preview-lotm.qml` -> `modules/rice/runtime/quickshell/preview-theme.qml`
- Updated launcher wiring in `modules/rice/nix/shell.nix` so the lotm variant resolves
  to the renamed entry roots.
- Kept lock wrapper loading and variant resolution behavior unchanged.

## Why

D-006 requires the runtime tree to contain zero theme knowledge. Earlier fixes removed
runtime theme literals in content and wrapper type names; this checkpoint closes the
remaining filename-level theme marker in runtime entry roots.

## Compatibility

- `rice-lock-screen --variant lotm` still works the same.
- Manifest/env variant resolution order is unchanged.
- Theme asset loading continues through runtime-neutral wrapper paths.

## Validation

- `scripts/rice-lint.sh` passed after rename + wiring update.
- `nix flake check` passed after rename + wiring update.
- Host eval/build smoke checks remained green (`shitbox`, `stickytop` eval; `shitbox` build).

## Decision Scope

This is an implementation checkpoint, not a new architectural decision. It aligns
existing implementation with active decisions D-006 and D-007.
