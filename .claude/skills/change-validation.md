## Objective

Require lightweight but explicit validation for every incremental change.

## Required Rules

- Define scope and expected visible outcome before editing.
- Validate the smallest useful unit first.
- Report what was tested and what was not tested.
- Capture residual risks and immediate next steps.

## Validation Matrix

- Nix: eval/build of affected host or module path.
- Home Manager: activation path for changed user config.
- Runtime/UI: visual checkpoint for affected surface.
- Theme: verify no regression across active and one alternate theme.
- Persistence/state: verify paths and permissions for new state files.

## Anti-Patterns To Reject

- Merging structural changes without validation evidence.
- Assuming unchanged behavior without checks.
- Mixing unrelated refactors into one validation cycle.

## Acceptance Checklist

- Scope is explicit.
- Validation evidence is explicit.
- Residual risk is explicit.
- Follow-up tasks are explicit and prioritized.

## Example Task Decomposition

- State change goal and blast radius.
- Apply minimal patch.
- Run targeted validations.
- Capture pass/fail outcomes.
- List follow-up hardening tasks.
