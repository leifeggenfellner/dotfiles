pragma Singleton
import QtQuick
import Quickshell
import ".." as Services

QtObject {
    id: themeLoader

    // Resolve relative to this file's location in the combined derivation:
    // runtime/ThemeLoader.qml -> ../generated/theme.json
    readonly property url configUrl: Qt.resolvedUrl("../generated/theme.json")

    property var data: ({})
    property string themeName: "lotm"
    property var pathways: []
    property var pathwayCatalog: []
    property string pathwaysDir: ""
    property string pathwaysPngDir: ""

    property var tokens: defaultTokens

    readonly property var defaultTokens: ({
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
                danger: "#f38ba8"
            },
            bar: {
                height: 56,
                radius: 12,
                margin: 8,
                spacing: 12,
                opacity: 0.85
            },
            radius: {
                chip: 8,
                sigil: 10,
                popout: 14
            },
            space: {
                xs: 4,
                sm: 8,
                md: 12,
                lg: 16
            },
            dur: {
                fast: 150,
                base: 250,
                slow: 350,
                overlay: 110
            },
            font: {
                display: "Cinzel",
                mono: "JetBrainsMono Nerd Font",
                sans: "Inter",
                sizeBar: 14,
                sizeSmall: 10,
                sizeIcon: 18
            },
            motionEnabled: true
        })

    function fileUrlToPath(url) {
        let s = String(url || "");
        if (s.startsWith("file://")) {
            // file:///abs/path -> /abs/path
            s = s.replace(/^file:\/\//, "");
        }
        return s;
    }

    function isInvalidFallbackPath(path) {
        let p = String(path || "");
        return p === "" || p.indexOf("qs-blackhole") >= 0 || p.startsWith("qrc:");
    }

    readonly property var defaultCatalog: [
        {
            id: "abyss",
            label: "Abyss",
            mainColor: "#d24131",
            glowColor: "#a92a1e"
        },
        {
            id: "black_emperor",
            label: "Black Emperor",
            mainColor: "#0f1115",
            glowColor: "#5f728e"
        },
        {
            id: "chained",
            label: "Chained",
            mainColor: "#ddd9eb",
            glowColor: "#8b80ba"
        },
        {
            id: "chaos_mist",
            label: "Chaos Mist",
            mainColor: "#658593",
            glowColor: "#72909c"
        },
        {
            id: "chaos_primogenitor",
            label: "Chaos Primogenitor",
            mainColor: "#b98467",
            glowColor: "#724635"
        },
        {
            id: "darkness",
            label: "Darkness",
            mainColor: "#c9deef",
            glowColor: "#5a6d93"
        },
        {
            id: "death",
            label: "Death",
            mainColor: "#e9f3da",
            glowColor: "#8a9f8b"
        },
        {
            id: "demoness",
            label: "Demoness",
            mainColor: "#bb4c8a",
            glowColor: "#c244a9"
        },
        {
            id: "door",
            label: "Door",
            mainColor: "#a0e8eb",
            glowColor: "#478eb0"
        },
        {
            id: "error",
            label: "Error",
            mainColor: "#f0f2ef",
            glowColor: "#8a96a7"
        },
        {
            id: "eternal_aeon",
            label: "Eternal Aeon",
            mainColor: "#c5d1e3",
            glowColor: "#656f94"
        },
        {
            id: "fool",
            label: "Fool",
            mainColor: "#c3c2d9",
            glowColor: "#756a92"
        },
        {
            id: "hanged_man",
            label: "Hanged Man",
            mainColor: "#b23137",
            glowColor: "#a53238"
        },
        {
            id: "hermit",
            label: "Hermit",
            mainColor: "#644d9f",
            glowColor: "#7d62b4"
        },
        {
            id: "justiciar",
            label: "Justiciar",
            mainColor: "#efeae7",
            glowColor: "#806c54"
        },
        {
            id: "moon",
            label: "Moon",
            mainColor: "#e3868c",
            glowColor: "#c0595d"
        },
        {
            id: "mother",
            label: "Mother",
            mainColor: "#d1eed2",
            glowColor: "#629a81"
        },
        {
            id: "paragon",
            label: "Paragon",
            mainColor: "#f0c685",
            glowColor: "#a96634"
        },
        {
            id: "patriarch",
            label: "Patriarch",
            mainColor: "#f1d9d7",
            glowColor: "#b14d82"
        },
        {
            id: "red_priest",
            label: "Red Priest",
            mainColor: "#c13e32",
            glowColor: "#cc473d"
        },
        {
            id: "second_law",
            label: "Second Law",
            mainColor: "#e2e8d6",
            glowColor: "#7c8b80"
        },
        {
            id: "sublunary_eye",
            label: "Sublunary Eye",
            mainColor: "#cfb387",
            glowColor: "#84633f"
        },
        {
            id: "sun",
            label: "Sun",
            mainColor: "#f6e68b",
            glowColor: "#bc9249"
        },
        {
            id: "twilight_giant",
            label: "Twilight Giant",
            mainColor: "#e38360",
            glowColor: "#a65c3b"
        },
        {
            id: "tyrant",
            label: "Tyrant",
            mainColor: "#a4edf7",
            glowColor: "#466bcb"
        },
        {
            id: "visionary",
            label: "Visionary",
            mainColor: "#deecf7",
            glowColor: "#8a9aa9"
        },
        {
            id: "wheel_of_fortune",
            label: "Wheel of Fortune",
            mainColor: "#d7e6eb",
            glowColor: "#849da2"
        },
        {
            id: "white_tower",
            label: "White Tower",
            mainColor: "#9ab4eb",
            glowColor: "#6678cc"
        }
    ]

    readonly property var defaultPathways: [
        {
            workspace: 1,
            id: "fool",
            label: "Fool",
            icon: "fool.png",
            color: "#756a92"
        },
        {
            workspace: 2,
            id: "door",
            label: "Door",
            icon: "door.png",
            color: "#478eb0"
        },
        {
            workspace: 3,
            id: "white_tower",
            label: "White Tower",
            icon: "white_tower.png",
            color: "#6678cc"
        },
        {
            workspace: 4,
            id: "visionary",
            label: "Visionary",
            icon: "visionary.png",
            color: "#8a9aa9"
        },
        {
            workspace: 5,
            id: "darkness",
            label: "Darkness",
            icon: "darkness.png",
            color: "#5a6d93"
        },
        {
            workspace: 6,
            id: "sun",
            label: "Sun",
            icon: "sun.png",
            color: "#bc9249"
        },
        {
            workspace: 7,
            id: "error",
            label: "Error",
            icon: "error.png",
            color: "#8a96a7"
        }
    ]

    Component.onCompleted: reload()

    function reload() {
        let xhr = new XMLHttpRequest();
        xhr.open("GET", configUrl, false);
        xhr.send();

        if (xhr.responseText && xhr.responseText.length > 0) {
            try {
                data = JSON.parse(xhr.responseText);
                themeName = data.theme || "lotm";
                pathways = (data.lotm && data.lotm.pathways) || [];
                pathwayCatalog = (data.lotm && data.lotm.pathwayCatalog) || [];
                pathwaysDir = (data.assets && data.assets.active && data.assets.active.pathwaysDir) || "";
                pathwaysPngDir = (data.assets && data.assets.active && data.assets.active.pathwaysPngDir) || "";
                tokens = data.tokens || defaultTokens;
            } catch (e) {
                console.warn("ThemeLoader: failed to parse theme.json:", e);
                applyDefaults();
            }
        } else {
            console.warn("ThemeLoader: could not read theme.json, using defaults");
            applyDefaults();
        }
    }

    function applyDefaults() {
        themeName = "lotm";
        pathways = defaultPathways;
        pathwayCatalog = defaultCatalog;
        tokens = defaultTokens;
        // Local dev fallback when running with --path and no generated theme.json.
        pathwaysDir = Services.RepoPaths.lotmPathwaysDir;
        pathwaysPngDir = Services.RepoPaths.lotmPathwaysPngDir;

        // Extra guard if root resolution becomes invalid in unusual runtimes.
        if (isInvalidFallbackPath(pathwaysDir) || isInvalidFallbackPath(pathwaysPngDir)) {
            pathwaysDir = "/proc/self/cwd/modules/rice/themes/lotm/assets/pathways";
            pathwaysPngDir = "/proc/self/cwd/modules/rice/themes/lotm/assets/pathways_png";
        }
    }
}
