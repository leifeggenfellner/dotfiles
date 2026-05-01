# AI Workflow Scaffold

This folder is a lightweight system to guide iterative rice development.

## Layout

- `agents/`: focused personas for different tasks.
- `skills/`: reusable implementation patterns.
- `instructions/`: process and guardrails.

## Recommended Flow Per Session

1. Read `instructions/session-start.md`.
2. Pick one agent from `agents/` based on current task.
3. Apply one or more skills from `skills/`.
4. Follow rules in `instructions/implementation-rules.md`.
5. Keep scope small and ship one visible improvement.

## Current Scope

This scaffold targets:

- NixOS + Home Manager configuration in this repo.
- Hyprland + Quickshell integration.
- Theme system with future rice switching (LOTM, Pokemon, etc.).
