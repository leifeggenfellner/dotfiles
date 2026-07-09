pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// ── ManifestLoader ────────────────────────────────────────────
// The ONLY file that reads theme manifest JSON, the themes.json
// index, and the active-theme pointer (D-018). Everything else
// goes through the Theme facade.
//
// Path resolution (D-003 two-layer switch):
//   $RICE_MANIFEST env override (dev loop)
//   → $XDG_STATE_HOME/rice/active pointer resolved via the
//     ~/.config/rice/themes.json index
//   → ~/.config/rice/manifest.json (Nix-default theme).
// Pointer, index, and manifest are all watched: rice-switch (or a
// manifest edit) re-themes the running shell live.
//
// Runtime defaults below are theme-NEUTRAL. The manifest is
// deep-merged over them, so `tokens` and `icons` are always
// complete and the shell renders sanely with no manifest at all.

Item {
    id: loader

    readonly property var _defaults: ({
            meta: {
                name: "",
                displayName: "runtime defaults"
            },
            tokens: {
                colors: {
                    bg: {
                        base: "#1e1e2e",
                        mantle: "#181825",
                        elevated: "#313244",
                        sunken: "#11111b",
                        surface1: "#45475a",
                        surface2: "#585b70"
                    },
                    fg: {
                        primary: "#cdd6f4",
                        muted: "#a6adc8",
                        subtle: "#7f849c"
                    },
                    accent: {
                        primary: "#cba6f7",
                        secondary: "#89b4fa",
                        tertiary: "#74c7ec"
                    },
                    state: {
                        ok: "#a6e3a1",
                        warn: "#f9e2af",
                        danger: "#f38ba8",
                        info: "#89dceb"
                    }
                },
                typography: {
                    families: {
                        display: "Inter",
                        sans: "Inter",
                        mono: "JetBrainsMono Nerd Font"
                    },
                    sizes: {
                        small: 10,
                        body: 13,
                        bar: 14,
                        heading: 18,
                        icon: 18
                    },
                    weights: {
                        regular: Font.Normal,
                        medium: Font.Medium,
                        bold: Font.Bold
                    }
                },
                metrics: {
                    radius: {
                        small: 8,
                        medium: 10,
                        large: 14
                    },
                    space: {
                        xs: 4,
                        sm: 8,
                        md: 12,
                        lg: 16
                    },
                    bar: {
                        height: 56,
                        margin: 8,
                        spacing: 12,
                        opacity: 0.85
                    }
                },
                motion: {
                    durations: {
                        fast: 150,
                        base: 250,
                        slow: 350,
                        overlay: 110
                    },
                    easings: {
                        standard: "OutCubic",
                        enter: "OutQuint",
                        exit: "InCubic",
                        emphasis: "OutBack"
                    },
                    ambient: false,
                    enabled: true
                },
                // Ambient-effect config (D-021); read only by core/Effects.
                effects: {
                    layers: []
                }
            },
            assets: {
                root: "",
                // Semantic icon names → glyphs. Themes remap freely; values
                // containing "/" are files relative to assets.root.
                icons: {
                    "terminal": "󰆍",
                    "files": "󰉋",
                    "browser": "󰈹",
                    "editor": "󰷈",
                    "music": "󰝚",
                    "settings": "󰒓",
                    "mail": "󰇮",
                    "chat": "󰭹",
                    "photos": "󰋩",
                    "calendar": "󰃭",
                    "weather": "󰖐",
                    "moon": "󰽥",
                    "moon-new": "󰽤",
                    "moon-waxing-crescent": "󰽧",
                    "moon-first-quarter": "󰽡",
                    "moon-waxing-gibbous": "󰽨",
                    "moon-full": "󰽢",
                    "moon-waning-gibbous": "󰽦",
                    "moon-last-quarter": "󰽣",
                    "moon-waning-crescent": "󰽩",
                    "notes": "󰠮",
                    "clipboard": "󰅌",
                    "pin": "󰐃",
                    "pin-off": "󰤱",
                    "trash": "󰆴",
                    "monitor": "󰍛",
                    "volume": "󰕾",
                    "volume-muted": "󰝟",
                    "brightness": "󰃠",
                    "wifi": "󰤨",
                    "wifi-off": "󰤭",
                    "ethernet": "󰈀",
                    "bluetooth": "󰂯",
                    "battery": "󰁹",
                    "battery-charging": "󰂄",
                    "power": "󰐥",
                    "lock": "󰌾",
                    "logout": "󰍃",
                    "reboot": "󰜉",
                    "refresh": "󰑐",
                    "play": "󰐊",
                    "pause": "󰏤",
                    "previous": "󰒮",
                    "next": "󰒭",
                    "bell": "󰂚",
                    "bell-off": "󰂛",
                    "unknown": "󰋗"
                },
                sounds: {},
                raster: {}
            },
            widgets: {},
            plugins: []
        })

    property var _fileManifest: ({})
    property bool loaded: false

    readonly property var manifest: _merge(_defaults, _fileManifest)
    readonly property var meta: manifest.meta
    readonly property var tokens: manifest.tokens
    readonly property var icons: manifest.assets.icons
    readonly property string assetsRoot: manifest.assets.root

    // ── Switch machinery (D-003/D-018) ────────────────────────
    // themes.json index (Nix-built) + mutable active pointer.
    property var themesIndex: ({})       // name → { displayName, manifest, preview, wallpapers }
    property string defaultTheme: ""
    property string pointerName: ""

    readonly property string activeTheme: {
        if (pointerName.length > 0 && themesIndex[pointerName] !== undefined)
            return pointerName;
        return defaultTheme;
    }

    readonly property string statePath: {
        const env = Quickshell.env("XDG_STATE_HOME");
        return (env && env.length > 0 ? env : Quickshell.env("HOME") + "/.local/state") + "/rice/active";
    }

    readonly property string manifestPath: {
        const env = Quickshell.env("RICE_MANIFEST");
        if (env && env.length > 0)
            return env;
        const entry = themesIndex[activeTheme];
        if (entry && entry.manifest)
            return entry.manifest;
        return Quickshell.env("HOME") + "/.config/rice/manifest.json";
    }

    // rice-switch nudges this after writing the pointer: a watch set
    // on a not-yet-existing pointer file does not fire on creation.
    function reload() {
        indexFile.reload();
        pointerFile.reload();
        file.reload();
    }

    function _merge(base, over) {
        const out = {};
        for (const k in base)
            out[k] = base[k];
        for (const k in over) {
            const b = out[k];
            const o = over[k];
            if (b && o && typeof b === "object" && typeof o === "object" && !Array.isArray(b) && !Array.isArray(o))
                out[k] = _merge(b, o);
            else
                out[k] = o;
        }
        return out;
    }

    function _apply(text) {
        try {
            loader._fileManifest = JSON.parse(text);
            loader.loaded = true;
        } catch (e) {
            console.warn("ManifestLoader: invalid manifest JSON:", e);
        }
    }

    FileView {
        id: file
        path: loader.manifestPath
        watchChanges: true
        onLoaded: loader._apply(file.text())
        onLoadFailed: console.info("ManifestLoader: no manifest at", loader.manifestPath, "— using runtime defaults")
        onFileChanged: file.reload()
    }

    FileView {
        id: indexFile
        path: Quickshell.env("HOME") + "/.config/rice/themes.json"
        watchChanges: true
        onLoaded: {
            try {
                const idx = JSON.parse(text());
                loader.themesIndex = idx.themes ?? {};
                loader.defaultTheme = idx.default ?? "";
            } catch (e) {
                console.warn("ManifestLoader: invalid themes.json:", e);
            }
        }
        onLoadFailed: console.info("ManifestLoader: no themes.json — switch machinery inactive")
        onFileChanged: reload()
    }

    FileView {
        id: pointerFile
        path: loader.statePath
        watchChanges: true
        onLoaded: loader.pointerName = text().trim()
        onLoadFailed: loader.pointerName = ""
        onFileChanged: reload()
    }

    IpcHandler {
        target: "rice"

        function reload(): void {
            loader.reload();
        }
        // Scripting/testing: `quickshell -c rice ipc call rice active`
        function active(): string {
            return loader.activeTheme;
        }
    }
}
