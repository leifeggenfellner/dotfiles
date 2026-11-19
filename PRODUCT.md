# Product

<!-- impeccable:product-schema 1 -->

## Platform

Linux desktop: a NixOS + Hyprland session whose shell is a Quickshell (QML)
runtime. Not a web product; design surfaces are Wayland layer-shell windows.

## Users

One person, the owner of this repo, using the machine all day for
development and everyday computing on a laptop (Intel Arc iGPU, battery) that
is often docked to two 2560×1440 monitors.

## Product Purpose

A themed desktop ("rice") that is fully usable as a daily driver while
immersing the session in a fictional world. Success is a desktop that feels
like living inside the theme's universe without ever costing speed, clarity
or battery.

## Positioning

A multi-theme framework, not a one-off rice: the Quickshell runtime is
theme-blind (D-006) and every theme supplies tokens, copy and assets through a
validated manifest. The bundled theme is Lord of the Mysteries (LoTM):
Victorian, steam-age Backlund, the Tarot Club, the 22 Beyonder pathways and
their sigils.

## Operating Context

Hyprland workspaces 1–7 are mapped to LoTM pathways. The shell owns the bar,
launcher, dashboard ("Observatory"), notifications, lockscreen, polkit prompt
and ambient effects. Changes ship by `nh os switch` and live theme switching
(`rice-switch`).

## Capabilities and Constraints

- Canonical architecture and decisions: `docs/architecture/` (DECISIONS.md is
  the law; D-numbers are referenced everywhere).
- Runtime stays theme-blind; theme-specific look arrives through tokens,
  `widgets.<id>.settings` and theme assets.
- Ambient motion runs under a governor (battery, fullscreen, reduce-motion).
- Tray menus stay app-native (D-036).

## Brand Commitments

- LoTM palette: dark umber grounds, parchment text, antique gold, fog blue,
  ritual crimson; Cinzel for display, Inter for running text, JetBrains Mono
  Nerd Font for code and numerals.
- Pathway sigils (`modules/rice/themes/lotm/assets/pathways`) identify
  workspaces and must stay.
- Diegetic copy: theme strings speak in-world beside the real information,
  never instead of it.

## Product Principles

1. In-world, but never at the cost of the real information.
2. Calm by default: ceremony is reserved for deliberate moments.
3. The runtime stays theme-blind; a theme is data and assets.
4. Every surface degrades cleanly: no capture, no motion, no theme.
