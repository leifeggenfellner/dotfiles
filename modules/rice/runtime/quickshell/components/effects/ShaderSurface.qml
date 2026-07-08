import QtQuick
import Quickshell.Io

// ── ShaderSurface ────────────────────────────────────────────
// Runtime-owned T2 shader loader (D-028). Production installs a
// generated shaders/manifest.json next to compiled .qsb files. Dev
// repo runs usually do not have those generated files, so this item
// simply stays inactive and lets the caller's T1/T0 fallback render.

Item {
    id: root

    property string shaderName: ""
    property color tint: "white"
    property real strength: 0.1
    property real speed: 1.0
    property real time: 0
    property real progress: 1
    property real edgeSoftness: 0.08
    property real bandStart: 0
    property real bandEnd: 1

    readonly property string _manifestPath: String(Qt.resolvedUrl("shaders/manifest.json")).replace(/^file:\/\//, "")
    property var _compiled: ({})
    property bool _manifestLoaded: false
    readonly property bool shaderReady: _manifestLoaded && (_compiled[shaderName] ?? false)
    readonly property bool usingShader: shaderLoader.item !== null && shaderLoader.item.status !== ShaderEffect.Error

    FileView {
        id: manifestFile
        path: root._manifestPath
        watchChanges: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                const next = {};
                for (const name of parsed.compiled ?? [])
                    next[name] = true;
                root._compiled = next;
                root._manifestLoaded = true;
            } catch (e) {
                root._compiled = {};
                root._manifestLoaded = false;
            }
        }
        onLoadFailed: {
            root._compiled = {};
            root._manifestLoaded = false;
        }
    }

    Loader {
        id: shaderLoader
        anchors.fill: parent
        active: root.shaderReady
        sourceComponent: ShaderEffect {
            property color tint: root.tint
            property real strength: root.strength
            property real speed: root.speed
            property real time: root.time
            property real progress: root.progress
            property real edgeSoftness: root.edgeSoftness
            property real bandStart: root.bandStart
            property real bandEnd: root.bandEnd
            property vector2d resolution: Qt.vector2d(Math.max(1, width), Math.max(1, height))

            anchors.fill: parent
            blending: true
            fragmentShader: Qt.resolvedUrl("shaders/" + root.shaderName + ".qsb")
            visible: status !== ShaderEffect.Error
        }
    }
}
