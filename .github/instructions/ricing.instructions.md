---
description: "Hyprland ricing, theming, and visual consistency rules for this NixOS dotfiles flake. Use when modifying UI appearance, colors, animations, widgets, bars, notifications, lock screen, terminals, or any visual element."
applyTo: "modules/themes/**,modules/services/hyprland.nix,modules/services/swaync.nix,modules/services/hyprpaper.nix,modules/services/hypridle.nix,modules/programs/hyprlock.nix,modules/programs/waybar.nix,modules/programs/wofi/**,modules/programs/eww/**,modules/programs/foot.nix,modules/programs/alacritty.nix,modules/programs/cava.nix,modules/programs/btop.nix,modules/programs/bat.nix,modules/programs/fastfetch.nix,modules/programs/starship.nix,modules/programs/qt.nix,modules/programs/fonts.nix,modules/scripts/_theme-switcher.nix"
---

# Hyprland Ricing Guidelines

## Design Philosophy

- **Conservative and sleek** — clean lines, minimal clutter, modern look. No gratuitous glow, neon, or heavy decoration unless the active rice calls for it
- **Multi-rice support** — the system must support distinct rice profiles. Current target aesthetics:
  - **Modern minimal** (catppuccin, nord, rose-pine, tokyo-night) — muted accents, subtle blur, understated elegance
  - **Synthwave / retro-futuristic** — vibrant neons, deeper contrast, heavier glow and gradients
- All visual parameters (colors, animations, rounding, gaps, fonts) should be **centralizable** so switching rice profiles changes the entire look, not just the palette
- When you see an opportunity to extract a hardcoded visual value into a centralized theme option, **suggest it immediately**

## Design Language

The current rice (modern minimal) follows these defaults — all centralized in `themes/_style.nix` and exposed as NixOS options at `environment.desktop.theme.style.*`:

| Property         | Option                                             | Default                          | Notes                                 |
| ---------------- | -------------------------------------------------- | -------------------------------- | ------------------------------------- |
| Primary accent   | `accentPrimary`                                    | **mauve**                        | Borders, highlights, active states    |
| Secondary accent | `accentSecondary`                                  | **blue**                         | Gradients paired with primary         |
| Background alpha | `opacityBar` / `opacityPopups` / `opacityTerminal` | **0.8 / 0.9 / 0.91**             | Never fully opaque on floating UI     |
| Corner rounding  | `rounding` / `roundingSmall`                       | **16px / 12px**                  | 16px windows, 12px inner widgets      |
| Border width     | `borderWidth`                                      | **2px**                          | Consistent across all UI              |
| Gaps             | `gapsInner` / `gapsOuter`                          | **7px**                          | Hyprland window gaps                  |
| Primary font     | `fontMono`                                         | **RobotoMono Nerd Font**         | Terminals, bars, widgets, lock screen |
| GTK font         | `fontSans`                                         | **Inter**                        | GTK apps, Qt inherits                 |
| Cursor           | `cursorName` / `cursorSize`                        | **capitaine-cursors-white / 16** | Used everywhere                       |

### Centralized Style Architecture

All visual constants live in **one place** and flow to every consumer:

```
themes/_style.nix          ← pure data: default values
    ↓
config/theme.nix           ← NixOS options: environment.desktop.theme.style.*
    ↓                          (override per-host in _machine.nix)
    ├── services/hyprland.nix  ← reads config.environment.desktop.theme.style.*
    └── themes/default.nix     ← HM bridge: config.theme.style.*
            ↓
            ├── waybar, wofi, hyprlock, swaync, eww, foot, etc.
```

- **NixOS modules** read: `config.environment.desktop.theme.style.<option>`
- **HM modules** read: `config.theme.style.<option>` (bridged from NixOS via `osConfig`)
- **Accent colors** use indirection: `s.accentPrimary` is a palette key name (e.g., `"mauve"`), then look up the actual color with `c.${s.accentPrimary}`
- **Override per-host** in `_machine.nix`: `environment.desktop.theme.style.rounding = 20;`
- **Override per-rice** (future): a rice-profile module can override the full style attrset

When adding or modifying visual elements, always read from `theme.style.*` — never hardcode geometry, opacity, font, or animation values.

## Color System

### Always Use the Palette

Never hardcode color values. Every UI element must pull colors from the theming system so the theme-switcher works end-to-end.

**26 semantic color names** available per palette:
`rosewater`, `flamingo`, `pink`, `mauve`, `red`, `maroon`, `peach`, `yellow`, `green`, `teal`, `sky`, `sapphire`, `blue`, `lavender`, `text`, `subtext1`, `subtext0`, `overlay2`, `overlay1`, `overlay0`, `surface2`, `surface1`, `surface0`, `base`, `mantle`, `crust`

### Color Access — Prefer Semantic Names

Two access patterns exist; **prefer semantic names** for new code:

| Pattern                               | When to use                                                                 |
| ------------------------------------- | --------------------------------------------------------------------------- |
| `config.theme.colors.<semantic>`      | **Preferred** — HM modules (waybar, wofi, hyprlock)                         |
| `config.colorScheme.palette.<base0X>` | Legacy — only if module already uses this pattern (foot, swaync, eww, cava) |
| Direct `import ./_palette.nix scheme` | NixOS-layer modules that lack HM context (services/hyprland.nix)            |

When touching a module that uses base16 names, migrating to semantic names is welcome but not required.

### Format Helpers (`themes/_fmt.nix`)

Always use these — never manually build color strings:

| Helper                    | Input           | Output                     | Use case                         |
| ------------------------- | --------------- | -------------------------- | -------------------------------- |
| `fmt.rgba hex alpha`      | `"cba6f7" 0.8`  | `rgba(203, 166, 247, 0.8)` | CSS/Hyprlock with transparency   |
| `fmt.rgb hex`             | `"cba6f7"`      | `rgb(cba6f7)`              | Hyprland settings                |
| `fmt.hex hex`             | `"cba6f7"`      | `#cba6f7`                  | CSS, GTK, general                |
| `fmt.hexAlpha hex suffix` | `"cba6f7" "cc"` | `#cba6f7cc`                | CSS with alpha suffix            |
| `fmt.rgbComponents hex`   | `"cba6f7"`      | `203, 166, 247`            | Inline CSS `rgba()` construction |

### Semantic Color Roles

Follow the established color role mapping:

| Role                | Color                       | Examples                                        |
| ------------------- | --------------------------- | ----------------------------------------------- |
| Accent / active     | `style.accentPrimary`       | Active borders, focused inputs, primary buttons |
| Secondary accent    | `style.accentSecondary`     | Gradients, links, secondary highlights          |
| Success / check     | `green`                     | Verified states, battery OK                     |
| Warning             | `yellow` / `peach`          | Caps lock, temperature, caution states          |
| Error / urgent      | `red`                       | Failed states, critical notifications           |
| Info                | `sky` / `teal`              | Network, informational indicators               |
| Primary text        | `text`                      | Main content                                    |
| Secondary text      | `subtext1` / `subtext0`     | Dimmed labels, timestamps                       |
| Borders (inactive)  | `surface0`                  | Inactive window borders, separators             |
| Surface backgrounds | `surface0`–`surface2`       | Elevated surfaces, hover states                 |
| Base backgrounds    | `base` / `mantle` / `crust` | Window backgrounds (with alpha)                 |

## Animations

### Philosophy

Animations should feel **modern and polished** — every transition (expanding, opening, closing, entering view, workspace switching, menu reveals) should be animated. But keep it restrained: smooth and purposeful, not flashy or distracting. The goal is a living, responsive UI, not a tech demo.

- **Everything should animate** — windows, layers, workspaces, menus, popups, fades
- **Keep it fast** — users should never wait for an animation to finish
- **Slight overshoot is good** — gives a sense of weight and polish
- **No excessive bounce or wobble** — one subtle overshoot, not spring physics

### Bezier Curves

| Name       | Points                  | Character                                                 |
| ---------- | ----------------------- | --------------------------------------------------------- |
| `wind`     | `0.05, 0.9, 0.1, 1.05`  | Snappy with slight overshoot — default for windows/layers |
| `winIn`    | `0.1, 1.1, 0.1, 1.1`    | Bouncy entrance                                           |
| `winOut`   | `0.3, -0.3, 0, 1`       | Anticipation on exit                                      |
| `liner`    | `1, 1, 1, 1`            | Linear — borders and border-angle loop                    |
| `overshot` | `0.13, 0.99, 0.29, 1.1` | Pronounced overshoot — workspace transitions              |

Reuse existing curves. Only define new beziers if the motion character genuinely requires it. Bezier definitions should ideally be centralized so different rices can swap animation feel.

### Animation Timing

- Window open/close/move: speed **5–6**
- Layers: speed **3–4** (faster than windows)
- Fades: speed **10** (quick)
- Border angle: speed **60**, looping (slow gradient rotation)
- Workspace switch: speed **6**, slidevert with overshot

Prefer vertical slide (`slidevert`) for workspace transitions, horizontal `slide` for windows.

### Animation Coverage

Ensure animations exist for all of these — if any are missing, add them:

- Window open / close / move / resize
- Layer open / close (menus, popups, overlays)
- Workspace switch
- Special workspace reveal
- Fade in/out
- Border color transitions

## Blur

Blur is a key part of the aesthetic. Current settings: size **8**, passes **4**, contrast **1.1**, noise **0.02**.

Layer rules grant blur + `ignorealpha` to: `wofi`, `waybar`, `swaync-notification-window`, `swaync-control-center`.

When adding new floating UI (widgets, popups, overlays), add corresponding layer rules for blur.

## Component Conventions

### Waybar

- Top bar, height 36, margin `6 8 0 8`
- Left: launcher + workspaces; Center: clock; Right: tray + system group
- System modules use **solid colored backgrounds** with inverted text (the background color becomes text color)
- Active workspace: `linear-gradient(135deg, mauve → blue)`
- All borders use accent color (`mauve`)

### Wofi

- Overlay layer, 20% width, centered
- Accent border on window, gradient box-shadow on focused search
- Selected entry inverts: accent bg + base text

### Hyprlock

- All labels use **RobotoMono Nerd Font**
- Time: size **120**, Date: size **28**, Quote: size **20**
- Input field: 280×50, outline thickness 2
- Background: wallpaper with blur passes 2, reduced brightness/contrast
- Positioned relative to `defaultMonitor` (per-host)

### SwayNC

- Right-anchored, 460px notifications, 500px control center
- 16px rounding on outer containers, 12px on inner widgets
- Notifications: semi-transparent base bg with accent border
- Urgency levels: default=blue border, critical=red border, low=surface border

### EWW

- Vertical left-side bar, 48px wide
- Currently uses 5px border radius — should be brought closer to 12px for consistency
- Workspace polling via socat on Hyprland socket

### Terminals

- Foot is primary (enabled by default), alpha **0.91**, font size **10**
- Keep terminal transparency consistent with the overall alpha range

## Theme Switcher Integration

The theme-switcher script (`scripts/_theme-switcher.nix`) does live reloading:

1. Writes to `_active-scheme.nix`
2. Hot-reloads swaync CSS, waybar (SIGUSR2)
3. Updates VS Code theme via settings.json
4. Triggers `nixos-rebuild switch` in background

When adding new themed components, consider whether they need a hot-reload hook in the theme-switcher. Components that read colors at build time (most Nix-configured apps) reload on rebuild. Components with runtime CSS (swaync, waybar) need explicit reload signals.

## Inconsistencies — Fix Immediately

These are known violations of the ricing guidelines. **Fix them as soon as you encounter them** during any work — don't wait for the user to be editing the specific file:

- **Wofi** declares `cursor = "Numix-Cursor"` — should be `capitaine-cursors-white`
- **Btop** theme hardcoded to `catppuccin_mocha` — doesn't follow palette switching
- **Bat** has no theme configured
- **Fastfetch** and **Starship** use ANSI color names instead of palette colors
- **Alacritty** uses FiraCode/JetBrainsMono fonts instead of RobotoMono Nerd Font
- **Alacritty** bell color is hardcoded `#ffffff`
- **EWW** border radius (5px) is much smaller than the rest of the rice (12–18px)
- **Dual color access** — modules inconsistently use `theme.colors` vs `colorScheme.palette`; migrate to semantic names

When you spot any new inconsistency (hardcoded colors, mismatched fonts, missing blur rules, etc.), flag and fix it immediately.

## Proactive Suggestions

When working on visual config, actively suggest improvements:

- **Architectural centralization** — if you see visual values (colors, rounding, gaps, font sizes, alpha, animation curves) hardcoded in individual modules instead of pulled from a central source, **suggest extracting them immediately**. The goal is full rice-profile switching.
- **Hyprland plugins** that could enhance the rice (hyprexpo for workspace overview, hyprtrails for cursor effects, hyprfocus for focus animations, hyprbars for window decorations)
- **New widgets or modules** for waybar/eww (weather, now-playing, system stats, custom applets)
- **Animation coverage** — missing transitions, smoother curves, per-window overrides
- **Color scheme additions** to `_palettes.nix` — especially synthwave / cyberpunk palettes for the synthwave rice
- **Alternative tools** that could improve the workflow (ags/astal as waybar/eww alternative, anyrun as wofi alternative)
- **Modularity improvements** — any opportunity to make the config more composable or DRY

Frame architectural and consistency fixes as actionable suggestions with a clear rationale. Don't apply without confirmation, but do flag them immediately — don't wait.
