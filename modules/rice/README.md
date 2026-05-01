# Rice Modules

This directory holds Nix-side rice architecture.

## Goals

- Keep one top-level selector: `rice.theme`.
- Keep themes isolated under `themes/<name>/`.
- Keep shared logic small and intentional.
- Keep runtime UI data generation explicit.

## Current Status

- Base options live in `default.nix`.
- Theme behavior modules are intentionally not wired yet.
