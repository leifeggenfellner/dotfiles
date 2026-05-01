# Implementation Rules

## Scope Discipline

- Ship one concrete improvement at a time.
- Prefer additive changes over rewrites.
- Keep old workflow available until replacement is verified.

## Nix and Runtime Boundaries

- Nix defines structure, options, and generated data.
- Quickshell defines runtime behavior and visuals.
- Hyprland integration should be generated from structured options.

## Naming and Layout

- Keep theme modules under `modules/rice/themes/<theme>/`.
- Keep shared helpers under `modules/rice/shared/` only when truly shared.
- Keep runtime theme code grouped by theme.

## Validation

- Run formatting checks when relevant.
- Validate rebuild before considering a task done.
- Confirm visible behavior after each change.

## Performance and UX

- Use subtle animation; avoid constant heavy effects.
- Prioritize readability over visual noise.
- Reduce simultaneous moving elements.
