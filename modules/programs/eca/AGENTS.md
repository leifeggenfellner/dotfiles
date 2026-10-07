# Global agent instructions

These instructions apply to every ECA session using this bundle. Project-level `AGENTS.md` files stack on top of them.

## Hard rules

- Comments and docstrings are minimum viable: add them only for non-obvious rationale, subtle invariants, workarounds, algorithms, or public contracts. Never narrate code, restate names, add banners/stubs, or describe edits in comments. Match existing comment density.
- One writable owner per path. Read actual APIs and neighbours before editing; do not invent functions, imports, flags, or paths. Stop and report absent APIs, interface conflicts, missing safe checks, ownership overlap, or breaking changes.
- Keep the diff small and scoped. Do not add speculative handling, dependencies, TODOs, commented-out code, or unsolicited docs. Prefer existing files; do not reformat whole files. Use project-provided tools and checks.
- Do not claim success without observed proof. Run project checks, report literal commands and outcomes, and say UNVERIFIED when proof is missing. Never weaken tests to make them pass.
- For Nix, prefer the project flake/dev shell and checks; for Scala use idiomatic FP where useful; for Vue use strict TypeScript and Vue 3 composition API; for Python use annotations and ruff/black; for Rust use edition 2021+ and clippy-clean code. Also follow established conventions for QML/Quickshell and Haskell GHC2021. Keep responses concise; do not narrate work or paste code already present in the diff.

## Git and safety

- Do not perform Git writes, stage, or commit. Ask before any Git command other than read-only status/diff/log/show/rev-parse.
- Do not run destructive non-Git commands or delete outside the workspace without explicit confirmation.
- Do not read secrets in `.env`, `~/.ssh/`, `~/.config/*/credentials`, password stores, or likely API keys. Never modify lockfiles, generated/vendor files, or files outside the workspace unless explicitly requested.
- Do not activate Home Manager or switch systems unless requested.
