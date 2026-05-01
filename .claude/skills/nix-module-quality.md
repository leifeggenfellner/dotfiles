## Objective

Keep NixOS and Home Manager modules modular, declarative, and easy to evolve.

## Required Rules

- One concern per module.
- Keep shared behavior in shared modules; keep host-specific behavior in host modules.
- Prefer explicit options and composition over hidden coupling.
- Keep defaults predictable and side effects minimal.
- Additive changes first; replace old paths only after validation.

## Anti-Patterns To Reject

- Mixing unrelated domains in one module.
- Duplicating the same option logic across modules.
- Embedding host-specific values in shared modules.
- Large rewrites without migration checkpoints.

## Acceptance Checklist

- Module purpose is clear in under one sentence.
- Option and config boundaries are obvious.
- No duplicate source of truth introduced.
- Affected hosts still evaluate/build as expected.
- New behavior can be reverted cleanly.

## Example Task Decomposition

- Define module goal.
- Add new option or config branch in one place.
- Wire module into existing composition.
- Validate host eval/build.
- Document follow-up cleanup tasks.
