pragma Singleton
import Quickshell
import QtQuick

QtObject {
    id: themeLoader

    readonly property string configPath: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/quickshell/generated/theme.json"

    property var data: ({})
    property string themeName: "lotm"
    property var pathways: []
    property string pathwaysDir: ""

    Component.onCompleted: reload()

    function reload() {
        let xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + configPath, false);
        xhr.send();

        if (xhr.status === 200 || xhr.status === 0) {
            try {
                data = JSON.parse(xhr.responseText);
                themeName = data.theme || "lotm";
                pathways = (data.lotm && data.lotm.pathways) || [];
                pathwaysDir = (data.assets && data.assets.active && data.assets.active.pathwaysDir) || "";
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
        pathways = [];
        pathwaysDir = "";
    }
}
