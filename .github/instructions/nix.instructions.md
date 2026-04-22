---
description: "Nix language conventions and module patterns for this dotfiles flake. Use when writing, editing, or reviewing any .nix file."
applyTo: "**/*.nix"
---

# Nix Conventions

## Module Structure

- Every module receives `{ config, lib, ... }` (HM modules also get `osConfig` and flake inputs via `extraSpecialArgs`)
- Declare options under custom roots: `program.*`, `service.*`, `system.*`, `environment.*` — never under upstream `programs.*` or `services.*`
- Gate all config behind `lib.mkIf cfg.enable` so modules are inert when disabled
- Bind `cfg = config.program.<name>` (or `service.<name>`) in a `let` block

## Option Declarations

- Use `lib.mkOption` with explicit `type`, `default`, and `description`
- Boolean enables: `lib.mkOption { type = lib.types.bool; default = false; description = "..."; }`
- Use `lib.types.str`, `lib.types.int`, `lib.types.listOf`, `lib.types.attrsOf` etc. — always specify types

## Style

- Use `lib.mkIf` and `lib.mkMerge` for conditional config — avoid `if/then/else` in module config blocks
- Prefer `with lib;` sparingly; explicit `lib.` prefix is clearer
- Use `pkgs.callPackage` for script derivations, `pkgs.writeShellApplication` for shell scripts
- Keep modules focused: one program/service per file
- Aggregator `default.nix` files collect child paths into lists — always register new modules there

## Cross-Layer Access

- HM modules access NixOS options via `osConfig` (e.g., `osConfig.environment.desktop.windowManager`)
- Flake inputs are available through `specialArgs`/`extraSpecialArgs` — never use `<nixpkgs>` or channels
- Host-specific values belong in `hosts/<host>/default.nix` or `modules/profiles/<host>/default.nix`, not in shared modules

## Formatting

- Use `nixpkgs-fmt` (the project formatter configured in the flake devShell)
- Indent with 2 spaces
- Align attribute sets when it improves readability
