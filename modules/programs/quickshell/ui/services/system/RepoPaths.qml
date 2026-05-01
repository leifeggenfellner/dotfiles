pragma Singleton
import QtQuick
import Quickshell

QtObject {
    id: repoPaths

    function isInvalidPath(path) {
        let p = String(path || "");
        return p.trim() === "" || p.indexOf("qs-blackhole") >= 0 || p.startsWith("qrc:");
    }

    function rootDir() {
        let root = String(Quickshell.workingDirectory || "");
        return isInvalidPath(root) ? "/proc/self/cwd" : root;
    }

    readonly property string dotfilesRoot: rootDir()
    readonly property string lotmPathwaysDir: dotfilesRoot + "/modules/rice/themes/lotm/assets/pathways"
    readonly property string lotmPathwaysPngDir: dotfilesRoot + "/modules/rice/themes/lotm/assets/pathways_png"
}
