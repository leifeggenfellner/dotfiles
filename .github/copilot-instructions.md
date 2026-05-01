# Copilot Repository Instructions

This repository uses an AI workflow scaffold in `.github/ai/`.

When helping with ricing work:

1. Follow `.github/ai/instructions/session-start.md` at the start of a task.
2. Use one agent profile from `.github/ai/agents/` as the task lens.
3. Apply relevant skill recipes from `.github/ai/skills/`.
4. Follow `.github/ai/instructions/implementation-rules.md` for scope and quality.

Primary technical goals:

- Keep Nix modules maintainable and declarative.
- Build Quickshell UI iteratively with visible checkpoints.
- Support clean theme switching (for example LOTM and Pokemon) without scattered conditionals.
