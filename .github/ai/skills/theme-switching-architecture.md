# Skill: Theme Switching Architecture

## When To Use

Use when introducing or refining support for multiple rices.

## Recipe

1. Add a single top-level `rice.theme` selector.
2. Import only one theme module bundle at a time.
3. Keep shared base thin and optional.
4. Store theme-specific logic inside each theme directory.
5. Validate switching by rebuilding both themes.

## Guardrails

- Do not spread `if theme == ...` checks across unrelated modules.
- Do not force all themes into the same content model.
- Keep theme assets and semantics isolated.

## Done Condition

- Theme switch is one option change.
- Each theme can evolve independently.
