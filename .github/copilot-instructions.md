# Copilot Repository Instructions

This repository uses an AI workflow scaffold in `.github/ai/`.

When helping with ricing work:

1. Follow `.github/ai/instructions/session-start.md` at the start of a task.
2. Use one agent profile from `.github/ai/agents/` as the task lens.
3. Apply relevant skill recipes from `.github/ai/skills/`.
4. Follow `.github/ai/instructions/implementation-rules.md` for scope and quality.
5. Give only code snippets and suggestions that I can implement myself, don't write any code in the files.

Preferred structural compromise for Quickshell runtime work:

- Use concern-based runtime folders where practical: `assets`, `components`, `modules`, `services`, `utils`, `scripts`, `plugins`, `extras`.
- Apply the skill `.github/ai/skills/quickshell-modular-layout.md` when placing or migrating files.
- Keep migrations incremental and non-breaking; avoid big-bang tree rewrites.

Primary technical goals:

- Keep Nix modules maintainable and declarative.
- Build Quickshell UI iteratively with visible checkpoints.
- Support clean theme switching (for example LOTM and Pokemon) without scattered conditionals.
