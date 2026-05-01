# Dotfiles Workflow

## Mission

Ship incremental, reversible improvements to this Nix + rice setup with clear structure, strict boundaries, and fast validation.

## Operating Principles

- Keep one source of truth per concern.
- Prefer additive changes over rewrites.
- Preserve existing host behavior unless explicitly in scope.
- Optimize for long-term maintainability over short-term speed.
- Keep architecture decisions obvious from file placement and naming.

## Session Start Protocol

- State one goal sentence:
  Goal: implement visible improvement for _scope_ without breaking existing workflow.
- Choose one primary lens:
  - Nix module quality
  - Quickshell runtime structure
  - Theme authoring
  - Validation and rollout safety
- Define a tiny deliverable that can be tested quickly.
- Identify affected hosts, users, and runtime surfaces before edits.

## Structure Rules

- Nix domain boundaries:
  - config for system shape and cross-cutting policy
  - hardware for machine/runtime platform constraints
  - programs for application/tooling behavior
  - services for daemons and long-lived infra behavior
  - hosts for machine-specific composition
  - rice for theme/UI architecture and runtime data
- Quickshell runtime boundaries:
  - utils, core, components, widgets, modules, services (see docs/architecture/ARCHITECTURE.md)
- Dependency direction:
  - modules -> components/services/utils
  - never reverse this direction
- Shared behavior belongs in shared modules; host specifics belong in host modules.

## Development Quality Contract

- Keep modules concern-focused and small.
- Use explicit options and composition, not scattered conditionals.
- Avoid duplication of options, token definitions, and runtime state ownership.
- Keep naming stable and descriptive.
- Document non-obvious architectural intent near the change.

## Theme and Runtime Contract

- Keep theme data centralized and feature logic theme-agnostic where possible.
- Avoid per-theme branching in unrelated feature files.
- Use shared tokens/helpers for theme-dependent rendering.
- Keep runtime state ownership explicit and localized.

## Validation Contract

- Validate the smallest relevant unit first.
- Capture validation evidence for:
  - Nix eval/build of affected host path
  - Home Manager activation path if user config changed
  - Runtime/UI behavior if surface changed
  - Theme behavior for active + one alternate theme when relevant
- Record residual risks and follow-up tasks.

## Scope Guardrails

- No broad tree rewrites in one task.
- No opportunistic migration of unrelated files.
- No breaking structure changes without phased migration notes.
- If risk is medium/high, split into checkpoints.

## Task Output Template

- What changed
- Why this structure/location
- Validation performed
- Residual risks
- Next safe increment

## Companion Skills

Use these together for stricter execution:

- [.claude/skills/nix-module-quality.md](.claude/skills/nix-module-quality.md)
- [.claude/skills/change-validation.md](.claude/skills/change-validation.md)
- For rice framework work, start from
  [.claude/skills/rice-architecture.md](.claude/skills/rice-architecture.md),
  which routes to the specialized rice skills and the canonical docs in
  [docs/architecture/](docs/architecture/).
