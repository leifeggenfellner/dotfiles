# Skill: Quickshell Animation Engine

## When To Use

Use when UI state changes need smooth transitions with a consistent feel.

## Recipe

1. Keep one shared engine loop.
2. Use animated values (spring or tween) as state adapters.
3. Subscribe UI components to animated values.
4. Keep theme differences in presets only.
5. Always provide cleanup for reload or unmount.

## Guardrails

- Do not create per-component animation loops.
- Avoid timers that are not cleaned up.
- Keep motion subtle and state-driven.

## Done Condition

- Workspace/app state changes animate smoothly.
- Theme can change visual style without changing engine core.
