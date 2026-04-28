---
description: "Nix language conventions, module patterns, and flake architecture for this NixOS dotfiles flake. Use when writing, editing, or reviewing any .nix file."
applyTo: "**/*.nix"
---

# Nix Conventions — Dotfiles Flake

## Flake Architecture

- Built on **flake-parts** with **import-tree** (`vic/import-tree`) — every `.nix` file under `modules/` is auto-imported recursively; no manual import lists needed
- NixOS modules register via `flake.nixosModules.<name>`, HM modules via `flake.homeModules.<name>`, per-system outputs via `perSystem`
- `flake.homeModules` is a custom option declared in `modules/options.nix`
- There is a single `modules/` tree — no separate `system/` tree

## Module Registration

- A flake-parts module takes `_:` or `{ inputs, ... }:` and sets `flake.nixosModules.<name>` or `flake.homeModules.<name>`
- The inner module function takes `{ config, lib, pkgs, ... }` (HM modules also get `osConfig` and flake inputs via `extraSpecialArgs`)
- Gate all config behind `lib.mkIf cfg.enable` so modules are inert when disabled
- Bind `cfg = config.program.<name>` (or `service.<name>`) in a `let` block

## Custom Option Namespaces

Declare options under these custom roots — never declare new options directly under upstream `programs.*` or `services.*`:

| Namespace                        | Layer | Purpose                                                               |
| -------------------------------- | ----- | --------------------------------------------------------------------- |
| `environment.desktop.*`          | NixOS | Desktop enable, window manager, develop mode                          |
| `environment.desktop.theme.*`    | NixOS | Scheme name, wallpaper                                                |
| `environment.desktop.monitors.*` | NixOS | Typed submodule per monitor (desc, name, resolution, position, scale) |
| `environment.gaming.*`           | NixOS | Gaming toggle                                                         |
| `environment.server.*`           | NixOS | Server toggle                                                         |
| `system.disks.*`                 | NixOS | Disko disk layout                                                     |
| `system.bluetooth.*`             | NixOS | Bluetooth toggle                                                      |
| `service.*`                      | NixOS | Per-service toggles (blueman, touchpad, bolt, etc.)                   |
| `program.*`                      | HM    | Per-program options                                                   |
| `service.*`                      | HM    | Per-service options (hypridle, hyprpaper, etc.)                       |
| `theme.colors`                   | HM    | Full named color palette (hex without `#`)                            |

Note: `service.*` is used in **both** NixOS and HM layers — same convention, different evaluation contexts.

Modules freely **configure** upstream `programs.*`/`services.*` in their `config` blocks; the restriction is on **declaring** new options.

## Option Declarations

- Use `lib.mkOption` with explicit `type`, `default`, and `description`
- Boolean enables: `lib.mkOption { type = lib.types.bool; default = false; description = "..."; }`
- Use `lib.types.str`, `lib.types.int`, `lib.types.listOf`, `lib.types.attrsOf` etc. — always specify types

## Host Composition

Each host lives under `modules/hosts/<hostname>/` with:

| File                          | Purpose                                                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `default.nix`                 | Composes `flake.nixosConfigurations.<host>` by merging **all** nixosModules + homeModules + upstream modules |
| `_machine.nix`                | NixOS hardware, user, GPU, option overrides (monitors, disks, bluetooth, touchpad)                           |
| `_home.nix`                   | HM per-host overrides (lock monitor, idle behavior)                                                          |
| `_hardware-configuration.nix` | Generated hardware scan                                                                                      |
| `_power-tuning.nix`           | TLP / power tuning                                                                                           |

- The `_` prefix marks host-private files
- Hosts import **all** `lib.attrValues config.flake.nixosModules` and **all** `lib.attrValues config.flake.homeModules` — new modules are available everywhere automatically
- Host-specific values belong in `_machine.nix` / `_home.nix`, not in shared modules

## Theming System

Color flow: `environment.desktop.theme.scheme` (NixOS, set per-host) → `_palette.nix` resolves from `_palettes.nix` → `theme.colors` (HM option) → consumed by all HM modules.

Style flow: `themes/_style.nix` (pure defaults) → `config/theme.nix` declares NixOS options at `environment.desktop.theme.style.*` → `themes/default.nix` bridges to HM as `config.theme.style.*`.

| File                        | Role                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------ |
| `themes/_palettes.nix`      | Pure data — scheme name → 26 named colors                                            |
| `themes/_active-scheme.nix` | Default scheme string                                                                |
| `themes/_palette.nix`       | Lookup function: `scheme → palette attrset`                                          |
| `themes/_style.nix`         | Pure data — default visual style values (rounding, gaps, fonts, animations)          |
| `themes/_fmt.nix`           | Format helpers: `rgba`, `rgb`, `hex`, `hexAlpha`, `rgbComponents`                    |
| `themes/_colors.nix`        | Bridge to nix-colors `colorScheme.palette`                                           |
| `themes/default.nix`        | Registers `themes-style`, `themes-palette`, `themes-gtk`, `themes-colors` HM modules |

- HM modules use `config.theme.colors.<colorName>` for palette colors and `config.theme.style.*` for visual parameters
- NixOS modules use `config.environment.desktop.theme.style.*` and import `_palette.nix` directly
- Use `_fmt.nix` helpers for Hyprland `rgb()`/`rgba()` conversions
- Available palettes: catppuccin-mocha, catppuccin-macchiato, catppuccin-frappe, catppuccin-latte, nord, tokyo-night, rose-pine

## Scripts

- `scripts/default.nix` is the aggregator: builds scripts via `pkgs.callPackage ./_<name>.nix { ... }` passing host-specific data (monitors, scheme, palette list)
- Script files use `pkgs.writeShellScriptBin`
- Register new scripts in `scripts/default.nix` and add them to `home.packages`

## Impermanence

- Root is wiped on every boot (`hardware/base.nix` — btrfs snapshot + fresh subvolume)
- NixOS persistence: `services/impermanence.nix` — persistent directories under `/persist`
- HM persistence: `services/persist.nix`
- Individual modules declare their own persistence entries (e.g., fish persists `.local/share/fish`)
- When adding stateful programs, always consider what needs to persist

## Cross-Layer Access

- HM modules access NixOS options via `osConfig` (e.g., `osConfig.environment.desktop.windowManager`)
- Flake inputs are available through `specialArgs`/`extraSpecialArgs` — never use `<nixpkgs>` or channels

## Style

- Use `lib.mkIf` and `lib.mkMerge` for conditional config — avoid `if/then/else` in module config blocks
- Prefer `with lib;` sparingly; explicit `lib.` prefix is clearer
- Use `pkgs.callPackage` for script derivations, `pkgs.writeShellApplication` for shell scripts
- Keep modules focused: one program/service per file

## Formatting

- Use `nixpkgs-fmt` (the project formatter)
- Pre-commit hooks run: statix, deadnix, nil, nixpkgs-fmt, shellcheck, beautysh
- Indent with 2 spaces
- Align attribute sets when it improves readability

## Proactive Suggestions

When working on this flake, actively suggest:

- **New tools / packages** that complement the existing setup (terminal utilities, shell integrations, Nix tooling)
- **Nix ecosystem upgrades** — newer module patterns, useful flake inputs, overlays, or NixOS options that simplify current config
- **Impermanence gaps** — stateful paths that should be persisted but aren't
- **Cross-host inconsistencies** — config that works on one host but would break on the other
- **Architectural improvements** — opportunities to centralize, deduplicate, or make config more modular. Flag immediately when spotted, don't wait for the user to ask

Frame suggestions as brief "Tip:" or "Consider:" callouts — don't apply them without confirmation.
