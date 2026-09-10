# Copilot Repository Instructions

This repository is a NixOS and Home Manager configuration with a contract-driven rice and Quickshell framework.

## Authorities

- `flake.nix` and modules under `modules/` are configuration sources of truth. Keep system policy, hardware/host composition, programs, services, and rice concerns in their existing owners.
- For rice work, `docs/architecture/DECISIONS.md`, `ARCHITECTURE.md`, and `contracts/` are Law. `.claude/skills/<name>/SKILL.md` contains task Practice and must not redefine Law.
- Preserve active architecture decisions. Contract changes require the matching decision and migration documentation described by the architecture records.

## Change Rules

- Start from the nearest controlling module, runtime layer, contract, failing command, or test. Make focused, reversible edits and preserve existing host behavior unless change is explicit.
- Never edit generated manifests, derived assets, build output, caches, `result` links, lock state, or mutable runtime data. Change the source of truth and use the established generator or build.
- Respect dirty worktrees and unrelated user changes. Do not activate Home Manager, deploy, publish, alter remote services, or perform destructive operations without explicit approval.
- Workers may implement changes in their owned area. Route Nix/Home Manager work to `nix-home-manager-worker`, rice/Quickshell work to `rice-quickshell-worker`, and multi-area work through `dotfiles-orchestrator`.
- Use `context-scout` for compact read-only discovery, `validation-runner` for command execution, and `evaluator` for final readiness review when available.

## Validation

- After the first edit, run the cheapest focused check that can falsify the change. Broaden according to risk.
- Use the repository's Nix formatting/evaluation commands and run `scripts/rice-lint.sh` for covered rice changes.
- Report exact commands and results, checks not run, generated-file handling, and any activation-time or visual verification still required.
